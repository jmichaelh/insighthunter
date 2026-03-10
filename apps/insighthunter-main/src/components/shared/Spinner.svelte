<script lang="ts">
  export let size:  'sm' | 'md' | 'lg' = 'md';
  export let color: string              = 'var(--color-primary)';
</script>

<span class="spinner spinner--{size}" style="--spin-color:{color}" aria-label="Loading" />

<style>
  .spinner {
    display: inline-block;
    border: 3px solid var(--color-sand-200);
    border-top-color: var(--spin-color);
    border-radius: 50%;
    animation: spin 0.7s linear infinite;
    flex-shrink: 0;
    &--sm { width: 16px; height: 16px; border-width: 2px; }
    &--md { width: 28px; height: 28px; border-width: 3px; }
    &--lg { width: 44px; height: 44px; border-width: 4px; }
  }
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
</style>
