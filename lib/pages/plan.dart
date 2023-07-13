import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vertretungsapp/api/api.dart';
import 'package:vertretungsapp/api/stundenplan24/models/plan.dart';
import 'package:vertretungsapp/components/back_button.dart';
import 'package:vertretungsapp/components/icon_button.dart';
import 'package:vertretungsapp/components/plan/filter_button.dart';
import 'package:vertretungsapp/components/plan/plan_list_item.dart';
import 'package:vertretungsapp/components/plan/reload_button.dart';

class PlanPage extends StatefulWidget {
  final String schoolClass;

  const PlanPage({Key? key, required this.schoolClass}) : super(key: key);

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late Future<Plan> plan;

  DateTime date = DateTime.now();
  DateTime initDate = DateTime.now();

  List<DateTime> holidays = [];

  void setDate(DateTime d) {
    setState(() {
      plan = getPlan(false, d);
      date = d;
    });
  }

  void addDate(bool reverse) async {
    var date = this.date;

    bool isWeekend(int weekDay) {
      return [6, 7].contains(weekDay);
    }

    // If the date is a holiday, keep adding 1 day until it is not a holiday
    while (holidays.contains(date)) {
      if (reverse) {
        date = date.subtract(const Duration(days: 1));
      } else {
        date = date.add(const Duration(days: 1));
      }
    }

    // Add/Subtract 1 day to/from the date and skip weekends
    if (reverse) {
      date = date.subtract(const Duration(days: 1));
      while (isWeekend(date.weekday)) {
        date = date.subtract(const Duration(days: 1));
      }
    } else {
      date = date.add(const Duration(days: 1));
      while (isWeekend(date.weekday)) {
        date = date.add(const Duration(days: 1));
      }
    }

    setDate(date);
  }

  @override
  void initState() {
    plan = getPlan().then((value) {
      setState(() {
        date = value.date;
        initDate = value.date;
        holidays = value.holidays;
      });
      return value;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const _TopBar(),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Klasse ',
                      style: Theme.of(context).textTheme.displayMedium,
                      children: <TextSpan>[
                        TextSpan(text: widget.schoolClass, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PlanSwitcher(date: date, planPage: this),
                  const SizedBox(height: 5),
                  FutureBuilder(
                      future: plan,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          return _PlanDisplay(short: widget.schoolClass, plan: snapshot.data!);
                        } else if (snapshot.hasError) {
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Kein Plan verfügbar!",
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                              ],
                            ),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        VPBackButton(),
        Spacer(),
        Row(
          children: [
            VPFilterButton(),
            VPReloadButton(),
          ],
        )
      ],
    );
  }
}

class _PlanSwitcher extends StatelessWidget {
  final DateTime date;
  final _PlanPageState planPage;

  const _PlanSwitcher({Key? key, required this.date, required this.planPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VPIconButton(onPressed: () => planPage.addDate(true), icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 30)),
        TextButton(
          onPressed: () {
            planPage.setDate(planPage.initDate);
          },
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                return Colors.transparent;
              },
            ),
            splashFactory: NoSplash.splashFactory,
          ),
          child: Column(
            children: [
              Text(intToWeekday(date.weekday)),
              Text(date.format("dd.MM.yyyy"), style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
        VPIconButton(onPressed: () => planPage.addDate(false), icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 30)),
      ],
    );
  }
}

String intToWeekday(int weekday) {
  List<String> weekdays = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"];
  return weekdays[weekday - 1];
}

class _PlanDisplay extends StatelessWidget {
  final String short;
  final Plan plan;

  const _PlanDisplay({Key? key, required this.short, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(plan.lastUpdated.format("dd.MM.yyyy HH:mm"),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary)),
          const SizedBox(height: 5),
          Expanded(
            child: ListView(
              children: plan.classes.firstWhere((element) => element.short == short).schedule.map((e) => VPPlanListItem(lesson: e)).toList(),
            ),
          )
        ],
      ),
    );
  }
}