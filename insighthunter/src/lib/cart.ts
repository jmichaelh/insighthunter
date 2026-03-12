import { writable, derived } from 'svelte/store';
import type { CartItem, Cart } from '$lib/types';

function createCartStore() {
  const CART_KEY = 'ih_cart';

  function loadFromStorage(): CartItem[] {
    if (typeof localStorage === 'undefined') return [];
    try {
      const raw = localStorage.getItem(CART_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch { return []; }
  }

  function saveToStorage(items: CartItem[]) {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CART_KEY, JSON.stringify(items));
    }
  }

  const { subscribe, set, update } = writable<CartItem[]>(loadFromStorage());

  function persistingUpdate(fn: (items: CartItem[]) => CartItem[]) {
    update(items => {
      const next = fn(items);
      saveToStorage(next);
      return next;
    });
  }

  return {
    subscribe,

    addItem(item: Omit<CartItem, 'quantity'>) {
      persistingUpdate(items => {
        const existing = items.find(i => i.planId === item.planId && i.billing === item.billing);
        if (existing) return items; // plan already in cart
        return [...items, { ...item, quantity: 1 }];
      });
    },

    removeItem(planId: string, billing: string) {
      persistingUpdate(items => items.filter(i => !(i.planId === planId && i.billing === billing)));
    },

    clear() {
      saveToStorage([]);
      set([]);
    },

    hasItem(planId: string): boolean {
      let has = false;
      subscribe(items => { has = items.some(i => i.planId === planId); })();
      return has;
    },
  };
}

export const cart = createCartStore();

export const cartCount  = derived(cart, $cart => $cart.length);
export const cartTotal  = derived(cart, $cart => $cart.reduce((sum, i) => sum + i.price * i.quantity, 0));
export const cartObject = derived(cart, ($cart): Cart => ({
  items: $cart,
  total: $cart.reduce((sum, i) => sum + i.price * i.quantity, 0),
}));
