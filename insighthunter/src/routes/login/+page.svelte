<script lang="ts">
  import { enhance } from '$app/forms';

  let email = $state('');
  let password = $state('');
  let loading = $state(false);
  let error = $state('');

  export let form: { error?: string } | null = null;
</script>

<svelte:head>
  <title>Log In — InsightHunter</title>
</svelte:head>

<div class="min-h-[80vh] flex items-center justify-center px-6 py-20">
  <div class="w-full max-w-md">
    <div class="text-center mb-10">
      <a href="/" class="text-2xl font-bold text-white">
        Insight<span class="text-violet-400">Hunter</span>
      </a>
      <h1 class="text-2xl font-bold text-white mt-6 mb-2">Welcome back</h1>
      <p class="text-white/50 text-sm">Log in to your CFO workspace</p>
    </div>

    <div class="bg-white/5 border border-white/10 rounded-2xl p-8">

      {#if form?.error || error}
        <div class="bg-red-500/10 border border-red-500/30 text-red-400 text-sm rounded-lg px-4 py-3 mb-6">
          {form?.error ?? error}
        </div>
      {/if}

      <form method="POST" use:enhance={() => {
        loading = true;
        return async ({ update }) => {
          loading = false;
          await update();
        };
      }} class="space-y-5">

        <div>
          <label for="email" class="block text-sm text-white/70 mb-2">Email address</label>
          <input
            id="email"
            name="email"
            type="email"
            autocomplete="email"
            required
            bind:value={email}
            class="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-white/30 text-sm focus:outline-none focus:border-violet-500 transition"
            placeholder="you@company.com"
          />
        </div>

        <div>
          <div class="flex items-center justify-between mb-2">
            <label for="password" class="text-sm text-white/70">Password</label>
            <a href="/forgot-password" class="text-xs text-violet-400 hover:text-violet-300 transition">Forgot password?</a>
          </div>
          <input
            id="password"
            name="password"
            type="password"
            autocomplete="current-password"
            required
            bind:value={password}
            class="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-white/30 text-sm focus:outline-none focus:border-violet-500 transition"
            placeholder="••••••••"
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          class="w-full bg-violet-600 hover:bg-violet-500 disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold py-3 rounded-xl transition text-sm"
        >
          {loading ? 'Signing in...' : 'Sign In'}
        </button>
      </form>

      <div class="mt-6 text-center text-sm text-white/40">
        Don't have an account?
        <a href="/signup" class="text-violet-400 hover:text-violet-300 transition ml-1">Start for free</a>
      </div>
    </div>
  </div>
</div>
