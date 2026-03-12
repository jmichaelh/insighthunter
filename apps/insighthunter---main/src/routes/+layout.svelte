<script lang="ts">
  import '../app.css';
  import Nav from '$lib/components/Nav.svelte';
  import Footer from '$lib/components/Footer.svelte';
  import Toast from '$lib/components/Toast.svelte';
  import CartDrawer from '$lib/components/CartDrawer.svelte';
  import type { LayoutData } from './$types';

  export let  LayoutData;
</script>

<Nav user={data.user} />
<CartDrawer />
<Toast />

<main>
  <slot />
</main>

<Footer />
