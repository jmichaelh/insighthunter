<script>
  export let variant = 'primary';
  export let size = 'md';
  export let href = null;
  export let type = 'button';
  export let disabled = false;
  export let full = false;
  export let extraClass = '';

  $: classes = [
    'btn',
    `btn--${variant}`,
    size !== 'md' ? `btn--${size}` : '',
    full ? 'btn--full' : '',
    extraClass,
  ].filter(Boolean).join(' ');
</script>

{#if href}
  <a {href} class={classes}><slot /></a>
{:else}
  <button {type} class={classes} {disabled}><slot /></button>
{/if}

<style>
  /* ── Base ─────────────────────────────────────────────────── */
  .btn {
    display:          inline-flex;
    align-items:      center;
    justify-content:  center;
    border-radius:    var(--radius-md);
    font-weight:      600;
    text-decoration:  none;
    white-space:      nowrap;
    transition:       background 0.15s, border-color 0.15s, color 0.15s, box-shadow 0.15s;
    cursor:           pointer;
    user-select:      none;
    text-align:       center;
    position:         relative;
  }
  .btn:focus-visible {
    outline:          2px solid var(--color-primary-dark);
    outline-offset:   2px;
  }
  .btn:disabled, .btn[disabled] {
    opacity:    0.6;
    cursor:     not-allowed;
    box-shadow: none;
  }

  /* ── Sizes ────────────────────────────────────────────────── */
  .btn--md { padding: 9px 18px;  font-size: 0.875rem; }
  .btn--sm { padding: 6px 14px;  font-size: 0.8rem; }
  .btn--lg { padding: 12px 22px; font-size: 0.95rem; }

  /* ── Full width ───────────────────────────────────────────── */
  .btn--full { width: 100%; }

  /* ── Variants ─────────────────────────────────────────────── */

  /* Primary */
  .btn--primary {
    background: var(--color-primary);
    color:      #fff;
    border:     1px solid var(--color-primary);
  }
  .btn--primary:hover:not(:disabled) {
    background: var(--color-primary-dark);
    border-color: var(--color-primary-dark);
  }
  .btn--primary:active:not(:disabled) {
    background: var(--color-primary-darker);
    border-color: var(--color-primary-darker);
  }
  .btn--primary:focus-visible { box-shadow: 0 0 0 2px var(--color-primary-light); }

  /* Ghost */
  .btn--ghost {
    background:   transparent;
    color:        var(--color-text);
    border:       1px solid transparent;
  }
  .btn--ghost:hover:not(:disabled) { background: var(--color-sand-100); }
  .btn--ghost:active:not(:disabled) { background: var(--color-sand-200); }

  /* Outline */
  .btn--outline {
    background:   transparent;
    color:        var(--color-text);
    border-color: var(--color-border);
  }
  .btn--outline:hover:not(:disabled) { background: var(--color-sand-100); }
  .btn--outline:active:not(:disabled) { background: var(--color-sand-200); }

  /* Danger */
  .btn--danger {
    background: var(--color-danger);
    color:      #fff;
    border:     1px solid var(--color-danger);
  }
  .btn--danger:hover:not(:disabled) {
    background: var(--color-danger-dark);
    border-color: var(--color-danger-dark);
  }
  .btn--danger:active:not(:disabled) {
    background: var(--color-danger-darker);
    border-color: var(--color-danger-darker);
  }
</style>
