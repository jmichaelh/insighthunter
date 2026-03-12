<script lang="ts">
  import { enhance } from '$app/forms';
  import type { ActionData } from './$types';

  export let form: ActionData;
  let loading = false;
</script>

<svelte:head><title>Create Account — InsightHunter</title></svelte:head>

<div class="min-h-screen bg-sand-100 flex items-center justify-center px-4 py-12">
  <div class="w-full max-w-md">
    <div class="text-center mb-8">
      <a href="/" class="inline-flex items-center gap-2 font-display text-2xl font-bold text-sand-900">
        <span class="text-3xl">🎯</span> InsightHunter
      </a>
      <h1 class="text-2xl font-display font-bold text-sand-900 mt-4">Create your free account</h1>
      <p class="text-sand-500 mt-1">No credit card required · Free forever tier</p>
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
          <label for="fullName" class="label">Full Name <span class="text-red-500">*</span></label>
          <input id="fullName" name="fullName" type="text" class="input" placeholder="Jane Smith" required autocomplete="name" />
        </div>
        <div>
          <label for="email" class="label">Email Address <span class="text-red-500">*</span></label>
          <input id="email" name="email" type="email" class="input" placeholder="jane@company.com" required autocomplete="email" />
        </div>
        <div>
          <label for="companyName" class="label">Company / Business Name</label>
          <input id="companyName" name="companyName" type="text" class="input" placeholder="Acme Consulting (optional)" />
        </div>
        <div>
          <label for="password" class="label">Password <span class="text-red-500">*</span></label>
          <input id="password" name="password" type="password" class="input" placeholder="Min 8 characters" required minlength="8" autocomplete="new-password" />
        </div>

        <div class="text-xs text-sand-400">
          By creating an account you agree to our
          <a href="/terms" class="text-accent underline">Terms of Service</a> and
          <a href="/privacy" class="text-accent underline">Privacy Policy</a>.
        </div>

        <button type="submit" disabled={loading} class="btn-primary w-full text-center">
          {loading ? 'Creating account...' : 'Create Free Account →'}
        </button>
      </form>

      <p class="text-center text-sm text-sand-500 mt-6">
        Already have an account?
        <a href="/auth/login" class="text-accent font-medium hover:underline">Log in</a>
      </p>
    </div>
  </div>
</div>
