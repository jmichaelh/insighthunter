<script lang="ts">
  import { showToast }  from '@/components/shared/Toast.svelte';
  import Spinner        from '@/components/shared/Spinner.svelte';
  import { api }        from '@/lib/api';
  import { storeUser }  from '@/lib/auth';
  import type { Tier }  from '@/types/apps';

  export let defaultTier: Tier = 'lite';

  // ── Field state ──────────────────────────────────────────────
  let name        = '';
  let orgName     = '';
  let email       = '';
  let password    = '';
  let confirmPass = '';
  let tier        = defaultTier;
  let showPass    = false;
  let loading     = false;
  let step        = 1;

  // ── Validation errors ─────────────────────────────────────────
  let errors: Record<string, string> = {};

  function validateStep1(): boolean {
    errors = {};
    if (!name.trim())
      errors.name = 'Full name is required.';
    if (!email.trim())
      errors.email = 'Email is required.';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
      errors.email = 'Enter a valid email address.';
    if (!password)
      errors.password = 'Password is required.';
    else if (password.length < 8)
      errors.password = 'Password must be at least 8 characters.';
    else if (!/[A-Z]/.test(password))
      errors.password = 'Include at least one uppercase letter.';
    else if (!/[0-9]/.test(password))
      errors.password = 'Include at least one number.';
    if (confirmPass !== password)
      errors.confirmPass = 'Passwords do not match.';
    return Object.keys(errors).length === 0;
  }

  function validateStep2(): boolean {
    errors = {};
    if (!orgName.trim())
      errors.orgName = 'Business name is required.';
    return Object.keys(errors).length === 0;
  }

  function nextStep(e: SubmitEvent) {
    e.preventDefault();
    if (validateStep1()) step = 2;
  }

  function prevStep() {
    step   = 1;
    errors = {};
  }

  // ── Password strength ─────────────────────────────────────────
  $: strength = (() => {
    if (!password) return 0;
    let s = 0;
    if (password.length >= 8)          s++;
    if (password.length >= 12)         s++;
    if (/[A-Z]/.test(password))        s++;
    if (/[0-9]/.test(password))        s++;
    if (/[^A-Za-z0-9]/.test(password)) s++;
    return s;
  })();

  $: strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong', 'Very Strong'][strength] ?? '';
  $: strengthColor = [
    '',
    '#c0392b',   // Weak    — danger red
    '#e0921e',   // Fair    — warning orange
    '#e0921e',   // Good    — warning orange
    '#3d9a6e',   // Strong  — success green
    '#2e7d5a',   // V.Strong — deep green
  ][strength] ?? '';

  // ── Submit ────────────────────────────────────────────────────
  async function handleSubmit(e: SubmitEvent) {
    e.preventDefault();
    if (!validateStep2()) return;

    loading = true;

    const res = await api.post<{
      token: string;
      user:  { userId: string; orgId: string; email: string; role: string };
    }>('/auth/register', { name, email, password, orgName, tier });

    loading = false;

    if ('error' in res) {
      if (res.status === 409) {
        errors.email = 'An account with this email already exists.';
        step = 1;
      } else if (res.status === 429) {
        showToast('Too many attempts. Please wait a moment.', 'warning');
      } else {
        showToast(res.error ?? 'Registration failed. Please try again.', 'error');
      }
      return;
    }

    storeUser(res.data.user as any);
    showToast('Account created! Welcome to InsightHunter 🎉', 'success', 2200);
    setTimeout(() => { window.location.href = '/dashboard'; }, 500);
  }

  // ── OAuth ─────────────────────────────────────────────────────
  function registerWithGoogle() {
    window.location.href = `/api/auth/oauth/google?intent=register&tier=${tier}`;
  }

  // ── Tier display labels ───────────────────────────────────────
  const TIER_LABELS: Record<Tier, string> = {
    lite:       'Free (Lite)',
    standard:   'Standard — $99/mo',
    pro:        'Pro — $199/mo',
    enterprise: 'Enterprise',
  };
</script>

<!-- ── Step progress indicator ───────────────────────────────── -->
<div class="reg-steps" aria-label="Registration progress">
  <div class="reg-step" class:active={step === 1} class:done={step > 1}>
    <span class="reg-step__num">{step > 1 ? '✓' : '1'}</span>
    <span>Your Account</span>
  </div>
  <div class="reg-step__line" />
  <div class="reg-step" class:active={step === 2}>
    <span class="reg-step__num">2</span>
    <span>Your Business</span>
  </div>
</div>

<!-- ════════════════════════════════════════════════════════════ -->
<!-- Step 1 — Account details                                     -->
<!-- ════════════════════════════════════════════════════════════ -->
{#if step === 1}
  <form class="auth-form" on:submit={nextStep} novalidate>

    <!-- Google OAuth -->
    <button type="button" class="oauth-btn" on:click={registerWithGoogle}>
      <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
        <path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.874 2.684-6.615z"/>
        <path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z"/>
        <path fill="#FBBC05" d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z"/>
        <path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z"/>
      </svg>
      Continue with Google
    </button>

    <div class="auth-divider"><span>or create account with email</span></div>

    <!-- Full name -->
    <div class="form-field" class:has-error={!!errors.name}>
      <label for="reg-name">Full Name</label>
      <input
        id="reg-name"
        type="text"
        bind:value={name}
        autocomplete="name"
        placeholder="Jane Smith"
        aria-invalid={!!errors.name}
        aria-describedby={errors.name ? 'reg-name-error' : undefined}
      />
      {#if errors.name}
        <span class="field-error" id="reg-name-error" role="alert">
          {errors.name}
        </span>
      {/if}
    </div>

    <!-- Email -->
    <div class="form-field" class:has-error={!!errors.email}>
      <label for="reg-email">Email</label>
      <input
        id="reg-email"
        type="email"
        bind:value={email}
        autocomplete="email"
        placeholder="you@example.com"
        aria-invalid={!!errors.email}
        aria-describedby={errors.email ? 'reg-email-error' : undefined}
      />
      {#if errors.email}
        <span class="field-error" id="reg-email-error" role="alert">
          {errors.email}
        </span>
      {/if}
    </div>

    <!-- Password -->
    <div class="form-field" class:has-error={!!errors.password}>
      <label for="reg-password">Password</label>
      <div class="input-with-action">
        <input
          id="reg-password"
          type={showPass ? 'text' : 'password'}
          bind:value={password}
          autocomplete="new-password"
          placeholder="Min. 8 characters"
          aria-invalid={!!errors.password}
          aria-describedby="reg-pass-hint {errors.password ? 'reg-pass-error' : ''}"
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

      <!-- Strength meter -->
      {#if password.length > 0}
        <div
          class="strength-meter"
          id="reg-pass-hint"
          aria-label="Password strength: {strengthLabel}"
        >
          <div class="strength-meter__bars" aria-hidden="true">
            {#each [1,2,3,4,5] as i}
              <div
                class="strength-meter__bar"
                style="background:{i <= strength ? strengthColor : 'var(--color-sand-200)'}"
              />
            {/each}
          </div>
          <span
            class="strength-meter__label"
            style="color:{strengthColor}"
          >
            {strengthLabel}
          </span>
        </div>
      {/if}

      {#if errors.password}
        <span class="field-error" id="reg-pass-error" role="alert">
          {errors.password}
        </span>
      {/if}
    </div>

    <!-- Confirm password -->
    <div class="form-field" class:has-error={!!errors.confirmPass}>
      <label for="reg-confirm">Confirm Password</label>
      <input
        id="reg-confirm"
        type="password"
        bind:value={confirmPass}
        autocomplete="new-password"
        placeholder="Repeat your password"
        aria-invalid={!!errors.confirmPass}
        aria-describedby={errors.confirmPass ? 'reg-confirm-error' : undefined}
      />
      {#if errors.confirmPass}
        <span class="field-error" id="reg-confirm-error" role="alert">
          {errors.confirmPass}
        </span>
      {/if}
    </div>

    <button type="submit" class="btn btn--primary btn--full">
      Continue →
    </button>

  </form>

<!-- ════════════════════════════════════════════════════════════ -->
<!-- Step 2 — Business details                                    -->
<!-- ════════════════════════════════════════════════════════════ -->
{:else}
  <form class="auth-form" on:submit={handleSubmit} novalidate>

    <!-- Business name -->
    <div class="form-field" class:has-error={!!errors.orgName}>
      <label for="reg-orgname">Business Name</label>
      <input
        id="reg-orgname"
        type="text"
        bind:value={orgName}
        autocomplete="organization"
        placeholder="Acme LLC"
        aria-invalid={!!errors.orgName}
        aria-describedby={errors.orgName ? 'reg-org-error' : undefined}
        disabled={loading}
      />
      {#if errors.orgName}
        <span class="field-error" id="reg-org-error" role="alert">
          {errors.orgName}
        </span>
      {/if}
    </div>

    <!-- Plan selector -->
    <div class="form-field">
      <label for="reg-tier">Plan</label>
      <select
        id="reg-tier"
        bind:value={tier}
        disabled={loading}
        class="form-select"
      >
        {#each Object.entries(TIER_LABELS) as [value, label]}
          <option value={value}>{label}</option>
        {/each}
      </select>
      {#if tier === 'lite'}
        <span class="field-hint">✅ No credit card required for Free tier.</span>
      {:else}
        <span class="field-hint">🔒 Billing setup completes after account creation.</span>
      {/if}
    </div>

    <!-- Legal consent -->
    <label class="checkbox-field">
      <input
        type="checkbox"
        required
        disabled={loading}
      />
      <span>
        I agree to InsightHunter's
        <a href="/terms"   target="_blank" rel="noopener noreferrer">Terms of Service</a>
        and
        <a href="/privacy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>.
      </span>
    </label>

    <!-- Back + Submit -->
    <div class="form-actions">
      <button
        type="button"
        class="btn btn--ghost"
        on:click={prevStep}
        disabled={loading}
      >
        ← Back
      </button>
      <button
        type="submit"
        class="btn btn--primary"
        style="flex:1"
        disabled={loading}
        aria-busy={loading}
      >
        {#if loading}
          <Spinner size="sm" color="#fff" />
          Creating account…
        {:else}
          Create Account
        {/if}
      </button>
    </div>

  </form>
{/if}

<style>
  /* ── Step indicator ──────────────────────────────────────── */
  .reg-steps {
    display:       flex;
    align-items:   center;
    margin-bottom: 1.5rem;
  }
  .reg-step {
    display:         flex;
    align-items:     center;
    gap:             7px;
    font-size:       0.8rem;
    color:           var(--color-text-muted);
    font-weight:     500;
    flex:            1;
    justify-content: center;
  }
  .reg-step.active { color: var(--color-text); font-weight: 700; }
  .reg-step.done   { color: var(--color-success); }

  .reg-step__num {
    width:           24px;
    height:          24px;
    border-radius:   50%;
    background:      var(--color-sand-200);
    color:           var(--color-sand-700);
    display:         flex;
    align-items:     center;
    justify-content: center;
    font-size:       0.75rem;
    font-weight:     700;
    flex-shrink:     0;
    transition:      background 0.2s, color 0.2s;
  }
  .reg-step.active .reg-step__num {
    background: var(--color-primary);
    color:      #fff;
  }
  .reg-step.done .reg-step__num {
    background: var(--color-success);
    color:      #fff;
  }
  .reg-step__line {
    flex:       1;
    height:     1px;
    background: var(--color-border);
    max-width:  48px;
  }

  /* ── Form layout ─────────────────────────────────────────── */
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
    color:           var(--color-text);
    transition:      background 0.15s, box-shadow 0.15s;
  }
  .oauth-btn:hover {
    background:  var(--color-sand-50);
    box-shadow:  var(--shadow-card);
  }

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

  /* ── Fields ──────────────────────────────────────────────── */
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
  .form-field input,
  .form-select {
    width:         100%;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-md);
    padding:       10px 12px;
    font-size:     0.9rem;
    background:    #fff;
    color:         var(--color-text);
    transition:    border-color 0.15s, box-shadow 0.15s;
    outline:       none;
    font-family:   inherit;
  }
  .form-field input:focus,
  .form-select:focus {
    border-color: var(--color-primary);
    box-shadow:   0 0 0 3px rgba(181,164,138,0.2);
  }
  .form-field input:disabled,
  .form-select:disabled {
    background: var(--color-sand-100);
    cursor:     not-allowed;
    opacity:    0.7;
  }
  .form-field input::placeholder { color: var(--color-sand-400); }

  .form-field.has-error input,
  .form-field.has-error .form-select {
    border-color: var(--color-danger);
  }
  .form-field.has-error input:focus {
    box-shadow: 0 0 0 3px rgba(192,57,43,0.15);
  }

  .field-error {
    font-size:   0.78rem;
    color:       var(--color-danger);
    display:     flex;
    align-items: center;
    gap:         4px;
  }
  .field-error::before { content: '⚠'; font-size: 0.7rem; }

  .field-hint {
    font-size: 0.78rem;
    color:     var(--color-text-muted);
  }

  /* ── Password show/hide ───────────────────────────────────── */
  .input-with-action {
    position: relative;
    display:  flex;
  }
  .input-with-action input {
    flex:          1;
    padding-right: 44px;
  }
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

  /* ── Password strength meter ─────────────────────────────── */
  .strength-meter {
    display:     flex;
    align-items: center;
    gap:         8px;
    margin-top:  2px;
  }
  .strength-meter__bars {
    display: flex;
    gap:     3px;
    flex:    1;
  }
  .strength-meter__bar {
    flex:          1;
    height:        4px;
    border-radius: 2px;
    transition:    background 0.25s ease;
  }
  .strength-meter__label {
    font-size:   0.75rem;
    font-weight: 600;
    min-width:   72px;
    text-align:  right;
    transition:  color 0.25s ease;
  }

  /* ── Checkbox consent ────────────────────────────────────── */
  .checkbox-field {
    display:     flex;
    align-items: flex-start;
    gap:         9px;
    font-size:   0.8rem;
    color:       var(--color-text-muted);
    cursor:      pointer;
    line-height: 1.5;
  }
  .checkbox-field input[type="checkbox"] {
    width:        16px;
    height:       16px;
    margin-top:   2px;
    flex-shrink:  0;
    accent-color: var(--color-primary);
    cursor:       pointer;
  }
  .checkbox-field a {
    color:           var(--color-primary-dark);
    text-decoration: underline;
  }
  .checkbox-field a:hover { color: var(--color-sand-800); }

  /* ── Step 2 action row ───────────────────────────────────── */
  .form-actions {
    display: flex;
    gap:     10px;
  }
</style>
