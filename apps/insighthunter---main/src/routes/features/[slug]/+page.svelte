<script lang="ts">
  import { cart, cartOpen } from '$lib/stores/cart';
  import { toasts } from '$lib/stores/toast';
  import { plans, addons } from '$lib/data/pricing';
  import type { PageData } from './$types';

  export let data: PageData;
  $: feature = data.feature;

  function getRelatedPlan() {
    if (feature.tier.includes('Free')) return plans[0];
    if (feature.tier.includes('Standard')) return plans[1];
    if (feature.tier.includes('Pro') || feature.tier.includes('Add-on')) return plans[2];
    return null;
  }

  function getAddon() {
    return addons.find(a => a.id === feature.slug || feature.slug.startsWith(a.id));
  }

  function handleCTA() {
    const addon = getAddon();
    if (addon) {
      cart.add({ id: addon.id, name: addon.name, price: addon.price, interval: addon.interval, type: 'addon' });
      toasts.show(`${addon.name} added to cart!`, 'success');
      cartOpen.set(true);
    } else {
      window.location.href = '/pricing';
    }
  }
</script>

<svelte:head>
  <title>{feature.name} — InsightHunter</title>
  <meta name="description" content="{feature.tagline} {feature.description}" />
</svelte:head>

<!-- Hero -->
<section class="bg-gradient-to-br from-sand-900 to-sand-800 text-white py-20 px-4">
  <div class="container mx-auto">
    <div class="max-w-3xl">
      <div class="text-6xl mb-4">{feature.icon}</div>
      <div class="inline-block bg-accent/20 text-accent text-sm font-medium px-3 py-1 rounded-full mb-4 border border-accent/30">
        {feature.tier}
      </div>
      <h1 class="text-5xl font-display font-bold mb-4">{feature.name}</h1>
      <p class="text-2xl text-accent mb-4 italic">{feature.tagline}</p>
      <p class="text-sand-300 text-lg mb-8">{feature.description}</p>
      <div class="flex gap-4">
        <button on:click={handleCTA} class="btn-primary text-lg px-8 py-4">
          Get {feature.name} →
        </button>
        <a href="/pricing" class="btn-secondary border-white/30 text-white hover:bg-white/10 text-lg px-8 py-4">
          See All Plans
        </a>
      </div>
    </div>
  </div>
</section>

<!-- Features & Benefits -->
<section class="section bg-white">
  <div class="container mx-auto">
    <div class="grid md:grid-cols-2 gap-16">
      <div>
        <h2 class="text-2xl font-display font-bold text-sand-900 mb-6">What's Included</h2>
        <ul class="space-y-3">
          {#each feature.features as f}
            <li class="flex items-start gap-3">
              <span class="text-accent font-bold mt-0.5">✓</span>
              <span class="text-sand-700">{f}</span>
            </li>
          {/each}
        </ul>
      </div>
      <div>
        <h2 class="text-2xl font-display font-bold text-sand-900 mb-6">Business Benefits</h2>
        <div class="space-y-4">
          {#each feature.benefits as b}
            <div class="flex items-start gap-3 p-4 bg-sand-50 rounded-xl border border-sand-200">
              <span class="text-2xl">💡</span>
              <span class="text-sand-800 font-medium">{b}</span>
            </div>
          {/each}
        </div>
      </div>
    </div>
  </div>
</section>

<!-- CTA -->
<section class="section bg-sand-900 text-white">
  <div class="container mx-auto text-center">
    <h2 class="text-3xl font-display font-bold mb-4">Ready to unlock {feature.name}?</h2>
    <div class="flex justify-center gap-4 mt-6">
      <button on:click={handleCTA} class="btn-primary text-lg px-8 py-4">Get Started →</button>
      <a href="/support" class="btn-secondary border-white/30 text-white hover:bg-white/10 text-lg px-8 py-4">Ask a Question</a>
    </div>
  </div>
</section>
