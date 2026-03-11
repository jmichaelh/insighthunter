<script lang="ts">
  import { page } from '$app/stores';
  import '../app.css';

  let menuOpen = $state(false);
  const navLinks = [
    { href: '/#features', label: 'Features' },
    { href: '/#pricing', label: 'Pricing' },
    { href: '/#testimonials', label: 'Testimonials' },
  ];
</script>

<div class="min-h-screen bg-[#071510] text-white flex flex-col">

  <!-- Navbar -->
  <header class="sticky top-0 z-50 bg-[#071510]/90 backdrop-blur border-b border-white/10">
    <div class="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
      <a href="/" class="text-xl font-bold tracking-tight text-white">
        Insight<span class="text-violet-400">Hunter</span>
      </a>

      <!-- Desktop Nav -->
      <nav class="hidden md:flex items-center gap-8 text-sm text-white/70">
        {#each navLinks as link}
          <a href={link.href} class="hover:text-white transition">{link.label}</a>
        {/each}
      </nav>

      <div class="hidden md:flex items-center gap-3">
        <a href="/login" class="text-sm text-white/70 hover:text-white transition">Log in</a>
        <a href="/signup" class="bg-violet-600 hover:bg-violet-500 text-white text-sm px-4 py-2 rounded-lg transition font-medium">
          Get Started Free
        </a>
      </div>

      <!-- Mobile Hamburger -->
      <button class="md:hidden text-white/70" onclick={() => menuOpen = !menuOpen}>
        {#if menuOpen}✕{:else}☰{/if}
      </button>
    </div>

    <!-- Mobile Menu -->
    {#if menuOpen}
      <div class="md:hidden px-6 pb-4 flex flex-col gap-4 text-sm text-white/80">
        {#each navLinks as link}
          <a href={link.href} onclick={() => menuOpen = false} class="hover:text-white">{link.label}</a>
        {/each}
        <a href="/login" class="hover:text-white">Log in</a>
        <a href="/signup" class="bg-violet-600 text-white px-4 py-2 rounded-lg text-center font-medium">
          Get Started Free
        </a>
      </div>
    {/if}
  </header>

  <!-- Page Slot -->
  <main class="flex-1">
    <slot />
  </main>

  <!-- Footer -->
  <footer class="border-t border-white/10 py-10 px-6 text-white/40 text-sm">
    <div class="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
      <span>© {new Date().getFullYear()} InsightHunter. All rights reserved.</span>
      <div class="flex gap-6">
        <a href="/privacy" class="hover:text-white/70 transition">Privacy</a>
        <a href="/terms" class="hover:text-white/70 transition">Terms</a>
        <a href="mailto:support@insighthunter.app" class="hover:text-white/70 transition">Support</a>
      </div>
    </div>
  </footer>
</div>
