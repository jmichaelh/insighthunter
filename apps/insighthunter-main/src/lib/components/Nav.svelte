<script lang="ts">
  import { page } from '$app/stores';
  import { cartCount, cartOpen } from '$lib/stores/cart';
  import { apps } from '$lib/data/apps';

  export let user: { email: string; plan: string } | null = null;

  let mobileOpen = false;
  let featuresOpen = false;

  $: isActive = (path: string) => $page.url.pathname === path;
</script>

<nav class="sticky top-0 z-50 bg-white/95 backdrop-blur border-b border-sand-200">
  <div class="container mx-auto px-4">
    <div class="flex items-center justify-between h-16">
      <!-- Logo -->
      <a href="/" class="flex items-center gap-2 font-display text-xl font-bold text-sand-900">
        <span class="text-2xl">🎯</span>
        <span>InsightHunter</span>
      </a>

      <!-- Desktop Nav -->
      <div class="hidden lg:flex items-center gap-6">
        <!-- Features Dropdown -->
        <div class="relative" on:mouseenter={() => featuresOpen = true} on:mouseleave={() => featuresOpen = false}>
          <button class="flex items-center gap-1 text-sand-700 hover:text-accent font-medium transition-colors">
            Features <span class="text-xs">▾</span>
          </button>
          {#if featuresOpen}
            <div class="absolute top-full left-0 mt-1 w-64 bg-white rounded-xl shadow-lg border border-sand-200 p-2">
              {#each apps as app}
                <a href="/features/{app.slug}"
                   class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-sand-100 transition-colors">
                  <span class="text-xl">{app.icon}</span>
                  <div>
                    <div class="text-sm font-medium text-sand-900">{app.name}</div>
                    <div class="text-xs text-sand-500 capitalize">{app.tier}</div>
                  </div>
                </a>
              {/each}
            </div>
          {/if}
        </div>

        <a href="/pricing" class="text-sand-700 hover:text-accent font-medium transition-colors"
           class:text-accent={isActive('/pricing')}>Pricing</a>
        <a href="/about" class="text-sand-700 hover:text-accent font-medium transition-colors">About</a>
        <a href="/support" class="text-sand-700 hover:text-accent font-medium transition-colors">Support</a>
      </div>

      <!-- Right side -->
      <div class="hidden lg:flex items-center gap-3">
        <!-- Cart -->
        <button on:click={() => cartOpen.set(true)}
                class="relative p-2 text-sand-700 hover:text-accent transition-colors">
          🛒
          {#if $cartCount > 0}
            <span class="absolute -top-1 -right-1 w-5 h-5 bg-accent text-white text-xs rounded-full flex items-center justify-center">
              {$cartCount}
            </span>
          {/if}
        </button>

        {#if user}
          <a href="/dashboard" class="btn-outline text-sm px-4 py-2">Dashboard</a>
          <a href="/account" class="btn-primary text-sm px-4 py-2">My Account</a>
        {:else}
          <a href="/auth/login" class="btn-outline text-sm px-4 py-2">Log In</a>
          <a href="/auth/register" class="btn-primary text-sm px-4 py-2">Get Started</a>
        {/if}
      </div>

      <!-- Mobile menu button -->
      <button class="lg:hidden p-2" on:click={() => mobileOpen = !mobileOpen}>
        {mobileOpen ? '✕' : '☰'}
      </button>
    </div>

    <!-- Mobile menu -->
    {#if mobileOpen}
      <div class="lg:hidden py-4 border-t border-sand-200 space-y-2">
        <a href="/features" class="block px-3 py-2 text-sand-700 hover:bg-sand-100 rounded-lg">Features</a>
        <a href="/pricing" class="block px-3 py-2 text-sand-700 hover:bg-sand-100 rounded-lg">Pricing</a>
        <a href="/about" class="block px-3 py-2 text-sand-700 hover:bg-sand-100 rounded-lg">About</a>
        <a href="/support" class="block px-3 py-2 text-sand-700 hover:bg-sand-100 rounded-lg">Support</a>
        <div class="pt-2 border-t border-sand-200 space-y-2">
          {#if user}
            <a href="/dashboard" class="block btn-outline text-sm">Dashboard</a>
          {:else}
            <a href="/auth/login" class="block btn-outline text-sm text-center">Log In</a>
            <a href="/auth/register" class="block btn-primary text-sm text-center">Get Started Free</a>
          {/if}
        </div>
      </div>
    {/if}
  </div>
</nav>
