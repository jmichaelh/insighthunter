<script lang="ts">
  import { enhance } from '$app/forms';
  import type { ActionData } from './$types';

  export let form: ActionData;
  let loading = false;
</script>

<svelte:head><title>Log In — InsightHunter</title></svelte:head>

<div class="min-h-screen bg-sand-100 flex items-center justify-center px-4 py-12">
  <div class="w-full max-w-md">
    <div class="text-center mb-8">
      <a href="/" class="inline-flex items-center gap-2 font-display text-2xl font-bold text-sand-900">
        <span class="text-3xl">🎯</span> InsightHunter
      </a>
      <h1 class="text-2xl font-display font-bold text-sand-900 mt-4">Welcome back</h1>
      <p class="text-sand-500 mt-1">Log in to your Auto-CFO dashboard</p>
    </div>

    <div class="card">
      {#if form?.error}
        <div class="bg-red-50 border border-red-200 text-red-700 text-sm px-4 py-3 rounded-lg mb-5">
          {form.error}
        </div>
      {/if}

      <form method="POST"
            use:enhance={() => { loading = true; return async ({ update }) => { loading = false; update(); }; }}
            class="space-y-5">
        <div>
          <label for="email" class="label">Email Address</label>
          <input id="email" name="email" type="email" class="input" placeholder="jane@company.com" required autocomplete="email" />
        </div>
        <div>
          <label for="password" class="label">Password</label>
          <input id="password" name="password" type="password" class="input" placeholder="••••••••" required autocomplete="current-password" />
          <div class="text-right mt-1">
            <a href="/auth/forgot-password" class="text-xs text-accent hover:underline">Forgot password?</a>
          </div>
        </div>

        <button type="submit" class="btn-primary w-full" disabled={loading}>
          {#if loading}Logging in...{:else}Log In →{/if}
        </button>
      </form>

      <div class="text-center mt-6 text-sm text-sand-500">
        Don't have an account? <a href="/auth/signup" class="text-accent hover:underline">Sign up</a>
      </div>
    </div>
  </div>
</div>
