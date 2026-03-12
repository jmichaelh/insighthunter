<script lang="ts">
  import { plans } from '$lib/data/pricing';
  import { features } from '$lib/data/features';
  import { cart, cartOpen } from '$lib/stores/cart';
  import { toasts } from '$lib/stores/toast';
  import type { LayoutData } from './$types';

  export let data: LayoutData;

  const highlights = features.slice(0, 6);

  function addFreePlan() {
    cart.add({ id: 'free', name: 'Insight Lite', price: 0, interval: 'month', type: 'plan' });
    toasts.show('Insight Lite added!', 'success');
    cartOpen.set(true);
  }
</script>

<svelte:head>
  <title>InsightHunter — The Auto-CFO for Small Business</title>
  <meta name="description" content="AI-powered financial insights, forecasting, and reporting for freelancers and small businesses. Stop flying blind — get your Auto-CFO today." />
</svelte:head>

<!-- Hero -->
<section class="bg-gradient-to-br from-sand-900 via-sand-800 to-sand-900 text-white py-24 px-4 relative overflow-hidden">
  <div class="absolute inset-0 opacity-5 bg-[radial-gradient(circle_at_30%_50%,#D4A853,transparent_60%)]" />
  <div class="container mx-auto text-center relative z-10">
    <div class="inline-flex items-center gap-2 bg-accent/20 text-accent px-4 py-2 rounded-full text-sm font-medium mb-6 border border-accent/30">
      🚀 Now in paid beta · Q1 2026
    </div>
    <h1 class="text-5xl md:text-7xl font-display font-bold mb-6 leading-tight">
      Stop Flying Blind.<br/>
      <span class="text-accent">Get Your Auto-CFO.</span>
    </h1>
    <p class="text-xl text-sand-300 max-w-2xl mx-auto mb-10">
      InsightHunter delivers enterprise-grade P&L reports, cash flow forecasts, and AI-powered financial advice
      for freelancers and small businesses — at a fraction of CFO cost.
    </p>
    <div class="flex flex-col sm:flex-row gap-4 justify-center">
      <a href="/auth/register" class="btn-primary text-lg px-8 py-4">Start Free → No Card Needed</a>
      <a href="/pricing" class="btn-secondary border-white/30 text-white hover:bg-white/10 text-lg px-8 py-4">See Pricing</a>
    </div>
    <p class="text-sand-400 text-sm mt-6">
      Join 1,000+ small business owners · Free forever tier available
    </p>
  </div>
</section>

<!-- Social Proof Bar -->
<section class="bg-sand-100 border-y border-sand-200 py-6 px-4">
  <div class="container mx-auto">
    <div class="flex flex-wrap justify-center gap-8 text-sm text-sand-600 font-medium">
      <span>🔒 Bank-level encryption</span>
      <span>⚡ Built on Cloudflare — 99.9% uptime</span>
      <span>💳 No credit card to start</span>
      <span>🤖 AI-powered insights</span>
      <span>📊 Real-time dashboards</span>
    </div>
  </div>
</section>

<!-- Problem/Solution -->
<section class="section bg-white">
  <div class="container mx-auto">
    <div class="grid md:grid-cols-2 gap-16 items-center">
      <div>
        <h2 class="text-4xl font-display font-bold text-sand-900 mb-6">
          QuickBooks gives you data.<br/>
          <span class="text-accent">InsightHunter gives you answers.</span>
        </h2>
        <div class="space-y-4">
          {#each [
            ['❌', 'Bookkeeping tools show numbers — not what they mean'],
            ['❌', 'Cash flow crises arrive with zero warning'],
            ['❌', 'Real CFOs cost $3,000–$10,000/month'],
            ['❌', 'Financial reports take hours to prepare manually']
          ] as [icon, text]}
            <div class="flex items-start gap-3 text-sand-600">
              <span>{icon}</span><span>{text}</span>
            </div>
          {/each}
        </div>
        <div class="mt-8 p-6 bg-accent/10 rounded-2xl border border-accent/20">
          <p class="text-sand-800 font-semibold text-lg">
            ✅ InsightHunter automates all of this — starting at $0/month.
          </p>
        </div>
      </div>
      <div class="bg-sand-50 rounded-2xl p-8 border border-sand-200">
        <h3 class="font-display text-2xl font-bold text-sand-900 mb-6">What You Get</h3>
        <div class="space-y-4">
          {#each [
            ['📊', 'Instant P&L & Cash Flow Reports', 'Upload CSV → reports in seconds'],
            ['🔮', 'AI Cash Flow Forecasting', 'See 3–12 months ahead with confidence'],
            ['🤖', 'Auto-CFO Insights', 'Actionable recommendations, not raw numbers'],
            ['📋', 'Client-Ready PDFs', 'Impress investors, lenders, and partners'],
            ['🏢', 'Business Formation', 'Entity selection to EIN to compliance']
          ] as [icon, title, desc]}
            <div class="flex items-start gap-3">
              <span class="text-2xl">{icon}</span>
              <div>
                <div class="font-semibold text-sand-900">{title}</div>
                <div class="text-sm text-sand-500">{desc}</div>
              </div>
            </div>
          {/each}
        </div>
      </div>
    </div>
  </div>
</section>

<!-- Feature Grid -->
<section class="section bg-sand-50">
  <div class="container mx-auto">
    <div class="text-center mb-12">
      <h2 class="text-4xl font-display font-bold text-sand-900 mb-4">Everything Your Business Needs</h2>
      <p class="text-sand-600 text-xl max-w-2xl mx-auto">
        A full suite of financial tools — all in one place, all working together.
      </p>
    </div>
    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {#each highlights as feature}
        <a href="/features/{feature.slug}"
           class="card hover:border-accent/40 hover:shadow-md transition-all group">
          <div class="text-4xl mb-4">{feature.icon}</div>
          <div class="flex items-center justify-between mb-2">
            <h3 class="font-display font-bold text-sand-900 text-lg">{feature.name}</h3>
            <span class="text-xs bg-sand-100 text-sand-600 px-2 py-1 rounded-full">{feature.tier}</span>
          </div>
          <p class="text-sand-600 text-sm mb-3">{feature.tagline}</p>
          <span class="text-accent text-sm font-medium group-hover:underline">Learn more →</span>
        </a>
      {/each}
    </div>
    <div class="text-center mt-8">
      <a href="/features" class="btn-outline">View All Features →</a>
    </div>
  </div>
</section>

<!-- Pricing Preview -->
<section class="section bg-white">
  <div class="container mx-auto">
    <div class="text-center mb-12">
      <h2 class="text-4xl font-display font-bold text-sand-900 mb-4">Simple, Transparent Pricing</h2>
      <p class="text-sand-600 text-xl">Start free. Upgrade when you're ready.</p>
    </div>
    <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      {#each plans as plan}
        <div class="card relative flex flex-col {plan.highlighted ? 'border-accent ring-2 ring-accent/20' : ''}">
          {#if plan.badge}
            <div class="absolute -top-3 left-1/2 -translate-x-1/2 bg-accent text-white text-xs font-bold px-3 py-1 rounded-full">
              {plan.badge}
            </div>
          {/if}
          <div class="mb-4">
            <h3 class="font-display font-bold text-sand-900 text-lg">{plan.name}</h3>
            <div class="mt-2">
              {#if plan.interval === 'custom'}
                <span class="text-2xl font-bold text-sand-900">Custom</span>
              {:else}
                <span class="text-3xl font-bold text-sand-900">${plan.price}</span>
                {#if plan.price > 0}<span class="text-sand-500 text-sm">/mo</span>{/if}
              {/if}
            </div>
          </div>
          <p class="text-sand-600 text-sm mb-4 flex-1">{plan.description}</p>
          <a href="/pricing"
             class="{plan.highlighted ? 'btn-primary' : 'btn-outline'} text-sm text-center">
            {plan.cta}
          </a>
        </div>
      {/each}
    </div>
    <div class="text-center">
      <a href="/pricing" class="text-accent font-medium hover:underline">
        Compare all features in detail →
      </a>
    </div>
  </div>
</section>

<!-- Testimonials -->
<section class="section bg-sand-900 text-white">
  <div class="container mx-auto">
    <h2 class="text-4xl font-display font-bold text-center mb-12">
      What Our Users Say
    </h2>
    <div class="grid md:grid-cols-3 gap-6">
      {#each [
        {
          quote: "InsightHunter replaced my $2,500/month fractional CFO. I get better insights and it costs me $199.",
          name: "Sarah K.", role: "Freelance Marketing Consultant"
        },
        {
          quote: "The cash flow forecast caught a crunch 2 months out. I raised my rates in time. Literally saved my business.",
          name: "Marcus T.", role: "Agency Owner, 12 employees"
        },
        {
          quote: "BizForma walked me through my LLC setup in 20 minutes. My lawyer quoted $1,500 for the same thing.",
          name: "Priya L.", role: "Independent Software Consultant"
        }
      ] as t}
        <div class="p-6 rounded-2xl bg-white/5 border border-white/10">
          <p class="text-sand-200 mb-4 italic">"{t.quote}"</p>
          <div class="font-semibold text-accent">{t.name}</div>
          <div class="text-sand-400 text-sm">{t.role}</div>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- CTA -->
<section class="section bg-accent">
  <div class="container mx-auto text-center">
    <h2 class="text-4xl font-display font-bold text-white mb-4">
      Ready to Meet Your Auto-CFO?
    </h2>
    <p class="text-white/80 text-xl mb-8 max-w-xl mx-auto">
      Join thousands of small businesses that finally have real financial visibility.
    </p>
    <div class="flex flex-col sm:flex-row gap-4 justify-center">
      <a href="/auth/register" class="bg-white text-accent font-bold px-8 py-4 rounded-lg hover:bg-sand-100 transition-colors text-lg">
        Start Free Today →
      </a>
      <a href="/support" class="border-2 border-white/40 text-white font-semibold px-8 py-4 rounded-lg hover:bg-white/10 transition-colors text-lg">
        Talk to Sales
      </a>
    </div>
  </div>
</section>
