<script lang="ts">
  const pillars = [
    {
      title: 'Compliance Hub',
      icon: '🛡️',
      items: ['Client-level compliance dashboard', 'Due date visibility', 'Engagement letter generation & e-sign', 'Audit-ready document history'],
    },
    {
      title: 'Ledger & Reconciliation',
      icon: '📒',
      items: ['Ledgers with full audit trail', 'Standardized chart-of-accounts templates', 'Industry-specific categorization', 'Ready-to-send financials'],
    },
    {
      title: 'Automation',
      icon: '⚙️',
      items: ['Template-driven engagement letters', 'Automated reminders & recurring rules', 'Storage management tools', 'Workflow automation'],
    },
    {
      title: 'Analytics & Forecasting',
      icon: '📈',
      items: ['Cash flow trends & KPI dashboards', 'Client-ready PDF Insight Packs', 'Forecast alerts', 'Variance notifications'],
    },
  ];

  const plans = [
    {
      name: 'Lite',
      price: '$0',
      period: '/mo',
      desc: 'Start for free, no credit card required.',
      cta: 'Get Started Free',
      href: '/signup',
      highlight: false,
      features: ['Manual CSV uploads', 'Basic compliance task tracking', '3 client profiles', 'Standard report templates', 'Email support'],
    },
    {
      name: 'Standard',
      price: '$49',
      period: '/mo',
      desc: 'For growing freelancers and small firms.',
      cta: 'Start Standard',
      href: '/signup?plan=standard',
      highlight: true,
      features: ['Automatic data ingestion', 'Full compliance hub with smart reminders', 'Up to 20 client profiles', 'Engagement letter generation & tracking', 'Branded client-ready report packs', 'Priority support'],
    },
    {
      name: 'Enterprise / AFP',
      price: '$149',
      period: '/mo',
      desc: 'For multi-entity firms and fractional CFOs.',
      cta: 'Start Enterprise',
      href: '/signup?plan=enterprise',
      highlight: false,
      features: ['Everything in Standard', 'Unlimited client profiles', 'Multi-entity management', 'White-label reporting', 'Advanced automation workflows', 'Dedicated account manager'],
    },
  ];

  const testimonials = [
    {
      quote: 'Before InsightHunter, compliance tasks were scattered across three different tools and a shared spreadsheet. Now everything is in one place and I actually trust nothing is slipping through.',
      author: 'Solo Accountant, 8 clients',
    },
    {
      quote: 'I manage 14 clients as a fractional CFO. The multi-entity dashboard and white-label reports have made me look like I have a full team. My clients love the professionalism.',
      author: 'Fractional CFO',
    },
    {
      quote: 'Automated reminders caught a filing deadline that would have slipped through a busy season. That one alert alone paid for the entire year\'s subscription.',
      author: 'Small Business Owner',
    },
  ];

  const steps = [
    { step: '01', title: 'Create your free account', desc: 'Sign up in seconds. No credit card, no commitment.' },
    { step: '02', title: 'Connect or upload your data', desc: 'Sync via QuickBooks or upload a CSV to get started immediately.' },
    { step: '03', title: 'Get instant financial clarity', desc: 'Your dashboard, reports, and compliance tasks are ready from day one.' },
  ];
</script>

<svelte:head>
  <title>InsightHunter — AI-Powered CFO Workspace</title>
  <meta name="description" content="CFO-level clarity for solo entrepreneurs, freelancers, and small businesses. Real-time cash flow, automated reporting, and compliance — starting free." />
</svelte:head>

<!-- Hero -->
<section class="relative px-6 pt-24 pb-20 text-center overflow-hidden">
  <div class="absolute inset-0 bg-gradient-radial from-violet-900/20 via-transparent to-transparent pointer-events-none"></div>
  <div class="max-w-4xl mx-auto relative z-10">
    <span class="inline-block bg-violet-600/20 text-violet-300 text-xs font-semibold px-3 py-1 rounded-full mb-6 border border-violet-500/30">
      AI-Powered CFO Workspace
    </span>
    <h1 class="text-4xl md:text-6xl font-bold leading-tight mb-6">
      Stop Flying Blind.<br />
      <span class="text-violet-400">Run Your Finances with Clarity.</span>
    </h1>
    <p class="text-white/60 text-lg md:text-xl max-w-2xl mx-auto mb-10">
      CFO-level clarity, built for the way you actually work. Real-time cash flow visibility, automated reporting, and financial confidence — starting free.
    </p>
    <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
      <a href="/signup" class="bg-violet-600 hover:bg-violet-500 text-white font-semibold px-8 py-3 rounded-xl transition text-base w-full sm:w-auto">
        Get Started Free →
      </a>
      <a href="/#features" class="text-white/60 hover:text-white text-sm transition">See how it works</a>
    </div>
    <p class="mt-4 text-white/30 text-xs">✓ No credit card required · ✓ Free plan available · ✓ Cancel anytime</p>
  </div>
</section>

<!-- Problem Section -->
<section class="px-6 py-20 bg-white/[0.02]">
  <div class="max-w-5xl mx-auto text-center mb-14">
    <h2 class="text-3xl md:text-4xl font-bold mb-4">Most Business Owners Are Flying Blind on Finances</h2>
    <p class="text-white/50 text-lg">Spreadsheets break. Accountants are reactive. By the time you notice a problem, you're already behind.</p>
  </div>
  <div class="max-w-5xl mx-auto grid md:grid-cols-3 gap-6">
    {#each [
      { icon: '📉', title: 'No Real-Time Picture', desc: "You're checking your bank balance and hoping for the best — that's a gamble, not a strategy." },
      { icon: '😰', title: 'Cash Flow Surprises', desc: 'Slow months, late invoices, unexpected expenses — without forecasting, you only find out in a crisis.' },
      { icon: '⏳', title: 'Reports That Never Happen', desc: 'You know you should be tracking KPIs and runway. But between running the business, it never gets done.' },
    ] as problem}
      <div class="bg-white/5 border border-white/10 rounded-2xl p-6">
        <div class="text-3xl mb-3">{problem.icon}</div>
        <h3 class="text-white font-semibold text-lg mb-2">{problem.title}</h3>
        <p class="text-white/50 text-sm leading-relaxed">{problem.desc}</p>
      </div>
    {/each}
  </div>
</section>

<!-- Four Pillars -->
<section id="features" class="px-6 py-20">
  <div class="max-w-6xl mx-auto">
    <div class="text-center mb-14">
      <h2 class="text-3xl md:text-4xl font-bold mb-4">Four Pillars. One Unified Workspace.</h2>
      <p class="text-white/50 text-lg">InsightHunter isn't isolated tools — it's a cohesive suite designed to work together from day one.</p>
    </div>
    <div class="grid md:grid-cols-2 gap-6">
      {#each pillars as pillar}
        <div class="bg-white/5 border border-white/10 rounded-2xl p-8 hover:border-violet-500/40 transition">
          <div class="text-4xl mb-4">{pillar.icon}</div>
          <h3 class="text-xl font-bold mb-4 text-white">{pillar.title}</h3>
          <ul class="space-y-2">
            {#each pillar.items as item}
              <li class="flex items-start gap-2 text-white/60 text-sm">
                <span class="text-violet-400 mt-0.5">✓</span> {item}
              </li>
            {/each}
          </ul>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- How It Works -->
<section class="px-6 py-20 bg-white/[0.02]">
  <div class="max-w-4xl mx-auto">
    <div class="text-center mb-14">
      <h2 class="text-3xl md:text-4xl font-bold mb-4">Up and Running in Three Steps</h2>
      <p class="text-white/50">No complicated setup. No weeks of onboarding. Real value in your first session.</p>
    </div>
    <div class="grid md:grid-cols-3 gap-8">
      {#each steps as s}
        <div class="text-center">
          <div class="text-5xl font-black text-violet-500/30 mb-4">{s.step}</div>
          <h3 class="text-white font-semibold text-lg mb-2">{s.title}</h3>
          <p class="text-white/50 text-sm">{s.desc}</p>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- Pricing -->
<section id="pricing" class="px-6 py-20">
  <div class="max-w-6xl mx-auto">
    <div class="text-center mb-14">
      <h2 class="text-3xl md:text-4xl font-bold mb-4">Plans That Grow With Your Business</h2>
      <p class="text-white/50">Start free and upgrade as your client roster grows. Core features on every plan.</p>
    </div>
    <div class="grid md:grid-cols-3 gap-6">
      {#each plans as plan}
        <div class="rounded-2xl p-8 border flex flex-col {plan.highlight ? 'bg-violet-600/10 border-violet-500' : 'bg-white/5 border-white/10'}">
          {#if plan.highlight}
            <span class="text-xs font-bold text-violet-300 bg-violet-500/20 px-3 py-1 rounded-full self-start mb-4">Most Popular</span>
          {/if}
          <h3 class="text-xl font-bold text-white mb-1">{plan.name}</h3>
          <div class="text-4xl font-black text-white mb-1">
            {plan.price}<span class="text-lg font-normal text-white/40">{plan.period}</span>
          </div>
          <p class="text-white/50 text-sm mb-6">{plan.desc}</p>
          <ul class="space-y-3 mb-8 flex-1">
            {#each plan.features as feature}
              <li class="flex items-start gap-2 text-white/70 text-sm">
                <span class="text-violet-400 mt-0.5">✓</span> {feature}
              </li>
            {/each}
          </ul>
          <a href={plan.href} class="block text-center py-3 rounded-xl font-semibold text-sm transition {plan.highlight ? 'bg-violet-600 hover:bg-violet-500 text-white' : 'bg-white/10 hover:bg-white/20 text-white'}">
            {plan.cta}
          </a>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- Testimonials -->
<section id="testimonials" class="px-6 py-20 bg-white/[0.02]">
  <div class="max-w-6xl mx-auto">
    <div class="text-center mb-14">
      <h2 class="text-3xl md:text-4xl font-bold mb-4">Firms That Made the Switch</h2>
      <p class="text-white/50">Real stories from accounting professionals who replaced spreadsheet chaos with InsightHunter.</p>
    </div>
    <div class="grid md:grid-cols-3 gap-6">
      {#each testimonials as t}
        <div class="bg-white/5 border border-white/10 rounded-2xl p-6">
          <p class="text-white/70 text-sm leading-relaxed mb-6 italic">"{t.quote}"</p>
          <p class="text-violet-400 text-sm font-medium">— {t.author}</p>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- Final CTA -->
<section class="px-6 py-24 text-center">
  <div class="max-w-2xl mx-auto">
    <h2 class="text-3xl md:text-4xl font-bold mb-4">Your Clients Deserve Better Than a Spreadsheet.</h2>
    <p class="text-white/50 mb-10">Join hundreds of firms and business owners who've replaced compliance chaos with clarity.</p>
    <a href="/signup" class="inline-block bg-violet-600 hover:bg-violet-500 text-white font-semibold px-10 py-4 rounded-xl transition text-base">
      Start Free — No Credit Card Required →
    </a>
  </div>
</section>
