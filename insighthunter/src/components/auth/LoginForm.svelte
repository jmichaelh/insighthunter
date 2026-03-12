<script lang="ts">
  import { showToast }  from '@/components/shared/Toast.svelte';
  import Spinner        from '@/components/shared/Spinner.svelte';
  import { api }        from '@/lib/api';
  import { storeUser }  from '@/lib/auth';

  export let redirect = '/dashboard';

  // ── Field state ──────────────────────────────────────────────
  let email       = '';
  let password    = '';
  let loading     = false;
  let showPass    = false;

  // ── Validation errors ─────────────────────────────────────────
  let errors: Record<string, string> = {};

  function validate(): boolean {
    errors = {};
    if (!email.trim())        errors.email    = 'Email is required.';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
                              errors.email    = 'Enter a valid email address.';
    if (!password)            errors.password = 'Password is required.';
    else if (password.length < 8)
                              errors.password = 'Password must be at least 8 characters.';
    return Object.keys(errors).length === 0;
  }

  // ── Submit ────────────────────────────────────────────────────
  async function handleSubmit(e: SubmitEvent) {
    e.preventDefault();
    if (!validate()) return;

    loading = true;

    const res = await api.post<{
      token: string;
      user:  { userId: string; orgId: string; email: string; role: string };
    }>('/auth/login', { email, password });

    loading = false;

    if ('error' in res) {
      if (res.status === 401) {
        errors.password = 'Incorrect email or password.';
      } else if (res.status === 429) {
        showToast('Too many attempts. Please wait a moment.', 'warning');
      } else {
        showToast(res.error ?? 'Login failed. Please try again.', 'error');
      }
      return;
    }

    storeUser(res.data.user as any);
    showToast('Welcome back!', 'success', 1800);

    // Small delay so toast is visible before redirect
    setTimeout(() => { window.location.href = redirect; }, 400);
  }

  // ── OAuth ─────────────────────────────────────────────────────
  function loginWithGoogle() {
    window.location.href = `/api/auth/oauth/google?redirect=${encodeURIComponent(redirect)}`;
  }
</script>

<!-- ── Form ────────────────────────────────────────────────────── -->
<form class="auth-form" on:submit={handleSubmit} novalidate>

  <!-- OAuth -->
  <button
    type="button"
    class="oauth-btn"
    on:click={loginWithGoogle}
    disabled={loading}
  >
    <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
      <path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.874 2.684-6.615z"/>
      <path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z"/>
      <path fill="#FBBC05" d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z"/>
      <path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z"/>
    </svg>
    Continue with Google
  </button>

  <div class="auth-divider">
    <span>or sign in with email</span>
  </div>

  <!-- Email -->
  <div class="form-field" class:has-error={!!errors.email}>
    <label for="login-email">Email</label>
    <input
      id="login-email"
      type="email"
      bind:value={email}
      autocomplete="email"
      placeholder="you@example.com"
      aria-describedby={errors.email ? 'login-email-error' : undefined}
      aria-invalid={!!errors.email}
      disabled={loading}
    />
    {#if errors.email}
      <span class="field-error" id="login-email-error" role="alert">
        {errors.email}
      </span>
    {/if}
  </div>

  <!-- Password -->
  <div class="form-field" class:has-error={!!errors.password}>
    <div class="form-field__label-row">
      <label for="login-password">Password</label>
      <a href="/auth/forgot-password" class="form-field__link" tabindex="0">
        Forgot password?
      </a>
    </div>
    <div class="input-with-action">
      <input
        id="login-password"
        type={showPass ? 'text' : 'password'}
        bind:value={password}
        autocomplete="current-password"
        placeholder="••••••••"
        aria-describedby={errors.password ? 'login-pass-error' : undefined}
        aria-invalid={!!errors.password}
        disabled={loading}
      />
      <button
        type="button"
        class="input-toggle"
        on:click={() => showPass = !showPass}
        aria-label={showPass ? 'Hide password' : 'Show password'}
        tabindex="-1"
      >
        {showPass ? '🙈' : '👁️'}
      </button>
    </div>
    {#if errors.password}
      <span class="field-error" id="login-pass-error" role="alert">
        {errors.password}
      </span>
    {/if}
  </div>

  <!-- Submit -->
  <button
    type="submit"
    class="btn btn--primary btn--full"
    disabled={loading}
    aria-busy={loading}
  >
    {#if loading}
      <Spinner size="sm" color="#fff" />
      Signing in…
    {:else}
      Sign In
    {/if}
  </button>

</form>

<style>
  .auth-form {
    display:        flex;
    flex-direction: column;
    gap:            1rem;
  }

  /* ── OAuth button ────────────────────────────────────────── */
  .oauth-btn {
    display:         flex;
    align-items:     center;
    justify-content: center;
    gap:             10px;
    width:           100%;
    padding:         10px 16px;
    background:      #fff;
    border:          1px solid var(--color-border);
    border-radius:   var(--radius-md);
    font-size:       0.9rem;
    font-weight:     500;
    cursor:          pointer;
    transition:      background 0.15s, box-shadow 0.15s;
    color:           var(--color-text);
  }
  .oauth-btn:hover:not(:disabled) {
    background:  var(--color-sand-50);
    box-shadow:  var(--shadow-card);
  }
  .oauth-btn:disabled { opacity: 0.6; cursor: not-allowed; }

  /* ── Divider ─────────────────────────────────────────────── */
  .auth-divider {
    display:     flex;
    align-items: center;
    gap:         10px;
    color:       var(--color-text-muted);
    font-size:   0.8rem;
  }
  .auth-divider::before,
  .auth-divider::after {
    content:    '';
    flex:       1;
    height:     1px;
    background: var(--color-border);
  }

  /* ── Form fields ─────────────────────────────────────────── */
  .form-field {
    display:        flex;
    flex-direction: column;
    gap:            5px;
  }
  .form-field label {
    font-size:   0.8rem;
    font-weight: 600;
    color:       var(--color-text);
  }
  .form-field__label-row {
    display:         flex;
    justify-content: space-between;
    align-items:     center;
  }
  .form-field__link {
    font-size:       0.78rem;
    color:           var(--color-text-muted);
    text-decoration: none;
  }
  .form-field__link:hover { color: var(--color-primary-dark); text-decoration: underline; }

  .form-field input {
    width:         100%;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-md);
    padding:       10px 12px;
    font-size:     0.9rem;
    background:    #fff;
    color:         var(--color-text);
    transition:    border-color 0.15s, box-shadow 0.15s;
    outline:       none;
  }
  .form-field input:focus {
    border-color: var(--color-primary);
    box-shadow:   0 0 0 3px rgba(181,164,138,0.2);
  }
  .form-field input:disabled { background: var(--color-sand-100); cursor: not-allowed; }
  .form-field input::placeholder { color: var(--color-sand-400); }

  .form-field.has-error input {
    border-color: var(--color-danger);
  }
  .form-field.has-error input:focus {
    box-shadow: 0 0 0 3px rgba(192,57,43,0.15);
  }

  .field-error {
    font-size: 0.78rem;
    color:     var(--color-danger);
    display:   flex;
    align-items: center;
    gap:       4px;
  }
  .field-error::before { content: '⚠'; font-size: 0.7rem; }

  /* ── Password toggle ─────────────────────────────────────── */
  .input-with-action {
    position: relative;
    display:  flex;
  }
  .input-with-action input { flex: 1; padding-right: 44px; }

  .input-toggle {
    position:      absolute;
    right:         10px;
    top:           50%;
    transform:     translateY(-50%);
    background:    none;
    border:        none;
    cursor:        pointer;
    font-size:     1rem;
    padding:       4px;
    line-height:   1;
    color:         var(--color-text-muted);
    border-radius: var(--radius-sm);
  }
  .input-toggle:hover { color: var(--color-text); }
</style>
