<script>
  export let variant = 'tan';
  export let extraClass = '';
</script>

<span class={`badge badge--${variant} ${extraClass}`}>
  <slot />
</span>

<style>
  .badge {
    padding: 2px 6px;
    border-radius: 99px;
    font-size: 0.75rem;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    white-space: nowrap;
    vertical-align: middle;
  }

  .badge--tan {
    background-color: var(--color-tan);
    color: var(--color-tan-dark);
  }

  .badge--success {
    background-color: var(--color-success-light);
    color: var(--color-success-dark);
  }

  .badge--warning {
    background-color: var(--color-warning-light);
    color: var(--color-warning-dark);
  }

  .badge--danger {
    background-color: var(--color-danger-light);
    color: var(--color-danger-dark);
  }

  .badge--info {
    background-color: var(--color-info-light);
    color: var(--color-info-dark);
  }

  .badge--role {
    background-color: var(--color-role-light);
    color: var(--color-role-dark);
  }
</style>
