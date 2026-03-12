<script>
  import Button from './Button.svelte';

  export let icon = '📭';
  export let title;
  export let description = null;
  export let ctaLabel = null;
  export let ctaHref = null;
</script>

<div class="empty-state">
  <div class="empty-state__icon">{icon}</div>
  <h3 class="empty-state__title">{title}</h3>
  {#if description}
    <p class="empty-state__desc">{description}</p>
  {/if}
  {#if ctaLabel && ctaHref}
    <Button href={ctaHref}>{ctaLabel}</Button>
  {/if}
</div>

<style>
  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3.5rem 1.5rem;
    text-align: center;
    gap: 0.75rem;
  }
  .empty-state__icon  { font-size: 3rem; line-height: 1; }
  .empty-state__title { font-size: 1.1rem; font-weight: 700; }
  .empty-state__desc  { font-size: 0.875rem; color: var(--color-text-muted); max-width: 380px; }
</style>
