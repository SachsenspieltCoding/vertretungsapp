<script lang="ts">
	import { onMount } from 'svelte';
	import { setFavorite } from '$lib/favorites.js';
	import type { PageData } from './+page';

	export let data: PageData;

	onMount(() => {
		setFavorite({
			schoolnumber: data.schoolnumber,
			id: data.id,
			short: data.short
		});
		location.href = '/';
	});
</script>
