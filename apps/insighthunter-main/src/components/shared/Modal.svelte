<script lang="ts">
  import { createEventDispatcher } from 'svelte';

  export let open:  boolean = false;
  export let title: string  = '';
  export let size:  'sm' | 'md' | 'lg' = 'md';

  const dispatch = createEventDispatcher<{ close: void }>();

  function close() {
    open = false;
    dispatch('close');
  }

  function onKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') close();
  }
</script>

<svelte:window on:keydown={onKeydown} />

{#if open}
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <div class="modal-overlay" on:click|self={close} role="dialog" aria-modal="true">
    <div class="modal modal--{size}">
      <div class="modal__header">
        <h2 class="modal__title">{title}</h2>
        <button class="modal__close" on:click={close} aria-label="Close">✕</button>
      </div>
      <div class="modal__body">
        <slot />
      </div>
      {#if $$slots.footer}
        <div class="modal__footer">
          <slot name="footer" />
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  .modal-overlay {
    position: fixed; inset: 0;
    background: rgba(34,31,26,0.5);
    display: flex; align-items: center; justify-content: center;
    z-index: 1000;
    padding: 1rem;
  }
  .modal {
    background: #fff;
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-elevated);
    display: flex; flex-direction: column;
    max-height: 90vh; overflow: hidden;
    width: 100%;
    &--sm { max-width: 400px; }
    &--md { max-width: 600px; }
    &--lg { max-width: 860px; }
  }
  .modal__header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 1.25rem 1.5rem;
    border-bottom: 1px solid var(--color-border);
  }
  .modal__title { font-size: 1.1rem; font-weight: 700; }
  .modal__close {
    background: none; border: none; cursor: pointer;
    font-size: 1rem; color: var(--color-text-muted);
    padding: 4px 8px; border-radius: var(--radius-sm);
    &:hover { background: var(--color-sand-100); }
  }
  .modal__body   { padding: 1.5rem; overflow-y: auto; flex: 1; }
  .modal__footer {
    padding: 1rem 1.5rem;
    border-top: 1px solid var(--color-border);
    display: flex; justify-content: flex-end; gap: 10px;
  }
</style>
