<svelte:head>
  <title>About — InsightHunter</title>
</svelte:head>

<section class="bg-sand-900 text-white py-20 px-4">
  <div class="container mx-auto text-center max-w-3xl">
    <h1 class="text-5xl font-display font-bold mb-4">Built for the Business Owner, Not the Accountant</h1>
    <p class="text-sand-300 text-xl">
      We believe every small business deserves the same financial clarity that Fortune 500 companies get from their CFO teams.
    </p>
  </div>
</section>

<section class="section bg-white">
  <div class="container mx-auto max-w-4xl">
    <div class="grid md:grid-cols-2 gap-16 items-center mb-20">
      <div>
        <h2 class="text-3xl font-display font-bold text-sand-900 mb-4">Our Mission</h2>
        <p class="text-sand-600 text-lg mb-4">
          65 million freelancers and 33 million small businesses in the US are making critical financial decisions without the data they need.
        </p>
        <p class="text-sand-600 mb-4">
          QuickBooks shows you numbers. A real CFO tells you what to do about them. InsightHunter does both — automatically, affordably, and instantly.
        </p>
        <p class="text-sand-600">
          We're an AI-powered SaaS built entirely on Cloudflare's edge network, delivering enterprise-grade financial intelligence to businesses that could never afford it before.
        </p>
      </div>
      <div class="bg-sand-50 rounded-2xl p-8 border border-sand-200">
        <h3 class="font-display font-bold text-sand-900 text-xl mb-6">By the Numbers</h3>
        <div class="grid grid-cols-2 gap-6">
          {#each [
            ['65M+', 'Freelancers in the US'],
            ['$100B+', 'Addressable market'],
            ['$3,000', 'Avg. monthly CFO cost'],
            ['$49', 'InsightHunter Standard']
          ] as [num, label]}
            <div>
              <div class="text-3xl font-bold text-accent">{num}</div>
              <div class="text-sm text-sand-500">{label}</div>
            </div>
          {/each}
        </div>
      </div>
    </div>

    <!-- Team -->
    <div class="text-center mb-12">
      <h2 class="text-3xl font-display font-bold text-sand-900 mb-4">The Team</h2>
    </div>
    <div class="grid md:grid-cols-2 gap-6 mb-16">
      {#each [
        { name: 'Founder & CEO', bio: 'Serial entrepreneur with deep roots in financial services and SaaS. Built InsightHunter to solve a problem faced firsthand.' },
        { name: 'Lead Analyst (CFA, MBA Finance)', bio: 'Former corporate finance analyst with expertise in financial modeling, forecasting, and CFO advisory.' }
      ] as member}
        <div class="card text-center">
          <div class="w-16 h-16 bg-accent/20 rounded-full flex items-center justify-center text-3xl mx-auto mb-4">👤</div>
          <h3 class="font-semibold text-sand-900 text-lg mb-2">{member.name}</h3>
          <p class="text-sand-500 text-sm">{member.bio}</p>
        </div>
      {/each}
    </div>

    <!-- Tech Stack -->
    <div class="bg-sand-50 rounded-2xl p-8 border border-sand-200">
      <h3 class="font-display font-bold text-sand-900 text-xl mb-6 text-center">Built on World-Class Infrastructure</h3>
      <div class="flex flex-wrap justify-center gap-4">
        {#each ['Cloudflare Workers', 'Cloudflare D1', 'Cloudflare KV', 'Cloudflare Pages', 'Workers AI', 'Stripe', 'SvelteKit'] as tech}
          <span class="bg-white border border-sand-200 text-sand-700 px-4 py-2 rounded-full text-sm font-medium">{tech}</span>
        {/each}
      </div>
    </div>
  </div>
</section>

<section class="section bg-accent">
  <div class="container mx-auto text-center">
    <h2 class="text-3xl font-display font-bold text-white mb-4">We're Raising Our Seed Round</h2>
    <p class="text-white/80 mb-2">Seeking $250k to reach 1,000 paying users in Year 1.</p>
    <p class="text-white/70 text-sm mb-8">50% Product · 30% GTM · 20% Operations</p>
    <a href="/support" class="bg-white text-accent font-bold px-8 py-4 rounded-lg hover:bg-sand-100 transition-colors">
      Investor Inquiries →
    </a>
  </div>
</section>
