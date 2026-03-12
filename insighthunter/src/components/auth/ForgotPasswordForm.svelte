<script lang="ts">
  import { api } from '@/lib/api';

  let email    = '';
  let loading  = false;
  let sent     = false;
  let error    = '';

  async function handleSubmit(e: SubmitEvent) {
    e.preventDefault();
    loading = true; error = '';
    const res = await api.post('/auth/forgot-password', { email });
    if ('error' in res) {
      error = res.error;
    } else {
      sent = true;
    }
    loading = false;
  }
</script>

{#if sent}
  <div class="auth-success">
    <p>✅ Check your email — we sent a reset link to <strong>{email}</strong>.</p>
    <a href="/auth/login" class="btn btn--ghost btn--full" style="margin-top:1rem">
      Back to Sign In
    </a>
  </div>
{:else}
  <form class="auth-form" on:submit={handleSubmit}>
    {#if error}<div class="auth-error">{error}</div>{/if}
    <p style="font-size:0.875rem;color:var(--color-text-muted)">
      Enter your email and we'll send you a link to reset your password.
    </p>
    <label class="form-field">
      <span>Email</span>
      <input type="email" bind:value={email} required autocomplete="email" />
    </label>
    <button type="submit" class="btn btn--primary btn--full" disabled={loading}>
      {loading ? 'Sending…' : 'Send Reset Link'}
    </button>
    <a href="/auth/login" class="btn btn--ghost btn--full">Cancel</a>
  </form>
{/if}

<style>
  .auth-success {
    text-align: center;
    padding: 1rem 0;
    font-size: 0.9rem;
    strong { color: var(--color-text); }
  }
</style>
