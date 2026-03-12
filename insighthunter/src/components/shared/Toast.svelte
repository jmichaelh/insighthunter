<script lang="ts" context="module">
  import { writable } from 'svelte/store';

  export type ToastType = 'success' | 'error' | 'info' | 'warning';

  interface ToastItem {
    id:      string;
    type:    ToastType;
    message: string;
  }

  export const toasts = writable<ToastItem[]>([]);

  export function showToast(message: string, type: ToastType = 'info', duration = 3500) {
    const id = crypto.randomUUID();
    toasts.update(t => [...t, { id, type, message }]);
    setTimeout(() => toasts.update(t => t.filter(x => x.id !== id)), duration);
  }
</script>

<script lang="ts">
  import { toasts } from './Toast.svelte';

  const ICONS: Record<ToastType, string> = {
    success: '✅',
    error:   '❌',
    warning: '⚠️',
    info:    'ℹ️',
  };
</script>

<div class="toast-container">
  {#each $toasts as toast (toast.id)}
    <div class="toast toast--{toast.type}">
      <span>{ICONS[toast.type]}</span>
      <span>{toast.message}</span>
    </div>
  {/each}
</div>

<style>
  .toast-container {
    position: fixed;
    bottom: 1.5rem;
    right: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 8px;
    z-index: 2000;
  }
  .toast {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 18px;
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    box-shadow: var(--shadow-elevated);
    animation: slide-in 0.2s ease;
    max-width: 360px;
    &--success { background: #edfaf3; border: 1px solid #3d9a6e; color: #1a5c3f; }
    &--error   { background: #fdf0ef; border: 1px solid #c0392b; color: #7b1a11; }
    &--warning { background: #fdf6ec; border: 1px solid #e0921e; color: #7a4a05; }
    &--info    { background: #eef4fb; border: 1px solid #2e86c1; color: #154360; }
  }
  @keyframes slide-in {
    from { transform: translateX(20px); opacity: 0; }
    to   { transform: translateX(0);    opacity: 1; }
  }
</style>
