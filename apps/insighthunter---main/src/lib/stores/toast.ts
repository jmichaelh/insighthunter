import { writable } from 'svelte/store';

export interface Toast {
  id: string;
  type: 'success' | 'error' | 'info';
  message: string;
}

function createToastStore() {
  const { subscribe, update } = writable<Toast[]>([]);
  return {
    subscribe,
    show(message: string, type: Toast['type'] = 'info') {
      const id = crypto.randomUUID();
      update(toasts => [...toasts, { id, type, message }]);
      setTimeout(() => update(toasts => toasts.filter(t => t.id !== id)), 4000);
    },
    dismiss(id: string) { update(toasts => toasts.filter(t => t.id !== id)); }
  };
}

export const toasts = createToastStore();
