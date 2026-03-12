<script lang="ts">
  import { plans, addons } from '$lib/data/pricing';
  import { cart, cartOpen } from '$lib/stores/cart';
  import { toasts } from '$lib/stores/toast';
  import type { PricingPlan, Addon } from '$lib/types/index';

  function addPlan(plan: PricingPlan) {
    if (plan.interval === 'custom') { window.location.href = '/support'; return; }
    const existing = $cart.find(i => i.type === 'plan');
    if (existing) cart.remove(existing.id);
    cart.add({
      id: plan.id, name: plan.name, price: plan.price,
      interval: plan.price === 0 ? 'free' : plan.interval,
      type: 'plan', stripePriceId: plan.stripePriceId
    });
    toasts.show(`${plan.name} added to cart!`, 'success');
    cartOpen.set(true);
  }

  function addAddon(addon: Addon) {
    cart.add({
      id: addon.id, name: addon.name, price: addon.price,
      interval: addon.interval, type: 'addon', stripePriceId: addon.stripePriceId
    });
    toasts.show(`${addon.name} added to cart!`, 'success');
    cartOpen.set(true);
  }
</script>

<svelte:head>
  <title>Pricing — InsightHunter</title>
  <meta name="description" content="Simple pricing for every stage of your business. From free to enterprise-grade AI CFO tools." />
</svelte:head>

<section class="bg-sand-900 text-white py-20 px-4">
  <div class="container mx-auto text-center">
    <h1 class="text-5xl font-display font-bold mb-4">Plans for Every Business</h1>
    <p class="text-sand-300 text-xl max-w-2xl mx-auto">
      Start free. No credit card required. Upgrade as you grow.
    </p>
  </div>
</section>

<!-- Main Plans -->
<section class="section bg-sand-50">
  <div class="container mx-auto">
    <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
      {#each plans as plan}
        <div class="card relative flex flex-col {plan.highlighted ? 'border-accent ring-2 ring-accent/20 scale-105' : ''}">
          {#if plan.badge}
            <div class="absolute -top-4 left-1/2 -translate-x-1/2 bg-accent text-white text-xs font-bold px-4 py-1.5 rounded-full shadow">
              {plan.badge}
            </div>
          {/if}
          <div class="mb-6">
            <h3 class="font-display font-bold text-sand-900 text-xl mb-2">{plan.name}</h3>
            <p class="text-sand-500 text-sm mb-4">{plan.description}</p>
            <div class="text-4xl font-bold text-sand-900">
              {#if plan.interval === 'custom'}
                <span class="text-2xl">Custom</span>
              {:else}
                ${plan.price}
                {#if plan.price > 0}
                  <span class="text-sand-400 text-base font-normal">/mo</span>
                {/if}
              {/if}
            </div>
          </div>

          <ul class="space-y-2 mb-8 flex-1">
            {#each plan.features as f}
              <li class="flex items-start gap-2 text-sm text-sand-700">
                <span class="text-green-500 mt-0.5">✓</span> {f}
              </li>
            {/each}
          </ul>

          <button on:click={() => addPlan(plan)}
                  class="{plan.highlighted ? 'btn-primary' : 'btn-outline'} w-full text-center">
            {plan.cta}
          </button>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- Add-ons -->
<section class="section bg-white">
  <div class="container mx-auto">
    <div class="text-center mb-12">
      <h2 class="text-3xl font-display font-bold text-sand-900 mb-3">Power-Up Add-ons</h2>
      <p class="text-sand-600">Add only what you need — no bloated bundles.</p>
    </div>
    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {#each addons as addon}
        <div class="card flex flex-col">
          <div class="flex-1">
            <h3 class="font-display font-bold text-sand-900 text-lg mb-1">{addon.name}</h3>
            <p class="text-sand-500 text-sm mb-4">{addon.description}</p>
            <div class="text-2xl font-bold text-accent">
              ${addon.price}
              <span class="text-sand-400 text-sm font-normal">
                {addon.interval === 'one-time' ? ' one-time' : '/mo'}
              </span>
            </div>
          </div>
          <button on:click={() => addAddon(addon)}
                  class="btn-outline mt-4 text-sm w-full text-center">
            Add to Cart
          </button>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- FAQ -->
<section class="section bg-sand-50">
  <div class="container mx-auto max-w-3xl">
    <h2 class="text-3xl font-display font-bold text-sand-900 text-center mb-10">Frequently Asked Questions</h2>
    <div class="space-y-6">
      {#each [
        ['Can I change plans anytime?', 'Yes — upgrade or downgrade at any time. Changes apply at your next billing cycle.'],
        ['Is there a free trial?', 'Standard and Pro plans include a 14-day free trial. No credit card required to start.'],
        ['What payment methods do you accept?', 'All major credit cards (Visa, Mastercard, Amex) via Stripe. ACH available for annual plans.'],
        ['Can I cancel anytime?', 'Absolutely. Cancel from your account dashboard with one click. No cancellation fees.'],
        ['Do you offer annual billing?', 'Yes — pay annually and save 2 months (17% discount). Contact us to switch.'],
        ['Is my financial data secure?', 'Yes. Data is encrypted at rest and in transit. We never sell your data. SOC2 compliance in progress.']
      ] as [q, a]}
        <details class="card cursor-pointer group">
          <summary class="font-semibold text-sand-900 list-none flex justify-between items-center">
            {q} <span class="text-accent group-open:rotate-180 transition-transform">▾</span>
          </summary>
          <p class="mt-3 text-sand-600 text-sm">{a}</p>
        </details>
      {/each}
    </div>
  </div>
</section>
