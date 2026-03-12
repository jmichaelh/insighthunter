<script lang="ts">
  import { cart, cartTotal, cartOpen } from '$lib/stores/cart';
  import { goto } from '$app/navigation';
</script>

{#if $cartOpen}
  <!-- Backdrop -->
  <button class="fixed inset-0 bg-black/40 z-40" on:click={() => cartOpen.set(false)} aria-label="Close cart" />

  <!-- Drawer -->
  <div class="fixed top-0 right-0 h-full w-full max-w-md bg-white z-50 shadow-2xl flex flex-col">
    <div class="flex items-center justify-between p-6 border-b border-sand-200">
      <h2 class="font-display text-xl font-bold text-sand-900">Your Cart</h2>
      <button on:click={() => cartOpen.set(false)} class="text-sand-500 hover:text-sand-900 text-2xl">✕</button>
    </div>

    <div class="flex-1 overflow-y-auto p-6">
      {#if $cart.length === 0}
        <div class="text-center py-16 text-sand-400">
          <div class="text-5xl mb-4">🛒</div>
          <p class="font-medium">Your cart is empty</p>
          <a href="/pricing" on:click={() => cartOpen.set(false)}
             class="btn-primary mt-4 inline-block text-sm">Browse Plans</a>
        </div>
      {:else}
        <div class="space-y-4">
          {#each $cart as item (item.id)}
            <div class="flex items-start justify-between p-4 rounded-xl bg-sand-50 border border-sand-200">
              <div>
                <div class="font-semibold text-sand-900">{item.name}</div>
                <div class="text-sm text-sand-500 capitalize">{item.interval}</div>
                <div class="text-accent font-bold">
                  ${item.price}{item.interval === 'month' ? '/mo' : item.interval === 'one-time' ? ' one-time' : ''}
                </div>
              </div>
              <button on:click={() => cart.remove(item.id)}
                      class="text-sand-400 hover:text-red-500 transition-colors text-xl">✕</button>
            </div>
          {/each}
        </div>
      {/if}
    </div>

    {#if $cart.length > 0}
      <div class="p-6 border-t border-sand-200 space-y-4">
        <div class="flex justify-between font-semibold text-lg">
          <span>Total</span>
          <span class="text-accent">${$cartTotal}/mo</span>
        </div>
        <button on:click={() => { cartOpen.set(false); goto('/cart'); }}
                class="btn-primary w-full text-center">Review & Checkout →</button>
        <button on:click={() => cart.clear()}
                class="w-full text-center text-sm text-sand-400 hover:text-sand-700 transition-colors">Clear cart</button>
      </div>
    {/if}
  </div>
{/if}
