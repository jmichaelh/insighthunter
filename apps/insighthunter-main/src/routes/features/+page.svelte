<script lang="ts">
  import { features } from '$lib/data/features';
</script>

<svelte:head>
  <title>Features — InsightHunter</title>
  <meta name="description" content="Explore InsightHunter's full suite: AI CFO insights, bookkeeping, cash flow forecasting, business formation, payroll, PBX, and more." />
</svelte:head>

<section class="bg-sand-900 text-white py-20 px-4">
  <div class="container mx-auto text-center">
    <h1 class="text-5xl font-display font-bold mb-4">Your Full Business Financial Suite</h1>
    <p class="text-sand-300 text-xl max-w-2xl mx-auto">
      Everything from bookkeeping to AI-powered forecasting, business formation to payroll — all in one platform.
    </p>
  </div>
</section>

<section class="section bg-sand-50">
  <div class="container mx-auto">
    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {#each features as feature}
        <a href="/features/{feature.slug}"
           class="card hover:border-accent/40 hover:shadow-md transition-all group flex flex-col">
          <div class="text-4xl mb-4">{feature.icon}</div>
          <div class="flex items-start justify-between mb-2 gap-2">
            <h3 class="font-display font-bold text-sand-900 text-xl">{feature.name}</h3>
            <span class="text-xs bg-accent/10 text-accent px-2 py-1 rounded-full whitespace-nowrap">{feature.tier}</span>
          </div>
          <p class="text-sand-600 text-sm mb-3 italic">{feature.tagline}</p>
          <p class="text-sand-500 text-sm flex-1 mb-4 line-clamp-2">{feature.description}</p>
          <span class="text-accent text-sm font-medium group-hover:underline">Explore {feature.name} →</span>
        </a>
      {/each}
    </div>
  </div>
</section>

<!-- CTA -->
<section class="section bg-accent">
  <div class="container mx-auto text-center">
    <h2 class="text-3xl font-display font-bold text-white mb-4">Ready to Get Started?</h2>
    <p class="text-white/80 mb-8">The free tier includes everything you need to get started. No credit card.</p>
    <a href="/auth/register" class="bg-white text-accent font-bold px-8 py-4 rounded-lg hover:bg-sand-100 transition-colors">
      Start Free Today →
    </a>
  </div>
</section>
