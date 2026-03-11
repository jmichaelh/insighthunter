import { writable, derived } from 'svelte/store';
import type { CartItem } from '$lib/types';

function createCartStore() {
  const STORAGE_KEY = 'ih_cart';
  const initial: CartItem[] = typeof localStorage !== 'undefined'
    ? JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]') : [];

  const { subscribe, set, update } = writable<CartItem[]>(initial);

  function persist(items: CartItem[]) {
    if (typeof localStorage !== 'undefined') localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
  }

  return {
    subscribe,
    add(item: CartItem) {
      update(items => {
        if (items.find(i => i.id === item.id)) return items;
        const next = [...items, item];
        persist(next);
        return next;
      });
    },
    remove(id: string) {
      update(items => {
        const next = items.filter(i => i.id !== id);
        persist(next);
        return next;
      });
    },
    clear() { set([]); persist([]); }
  };
}

export const cart = createCartStore();
export const cartTotal = derived(cart, $cart => $cart.reduce((sum, item) => sum + item.price, 0));
export const cartCount = derived(cart, $cart => $cart.length);
export const cartOpen = writable(false);
