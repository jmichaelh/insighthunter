<script lang="ts">
  import { enhance } from '$app/forms';
  import type { PageData, ActionData } from './$types';

  export let data: PageData;
  export let form: ActionData;
</script>

<svelte:head>
  <title>Support — InsightHunter</title>
</svelte:head>

<section class="bg-sand-900 text-white py-20 px-4">
  <div class="container mx-auto text-center max-w-3xl">
    <h1 class="text-5xl font-display font-bold mb-4">We're Here to Help</h1>
    <p class="text-sand-300 text-xl">Real humans, fast responses. Average reply time: under 4 hours.</p>
  </div>
</section>

<section class="section bg-sand-50">
  <div class="container mx-auto">
    <!-- Support channels -->
    <div class="grid md:grid-cols-3 gap-6 mb-16">
      {#each [
        { icon: '📧', title: 'Email Support', desc: 'support@insighthunter.com', detail: 'Response within 4 hours on business days.' },
        { icon: '💬', title: 'Live Chat', desc: 'Pro & Standard plans', detail: 'Real-time chat within the dashboard. Available 9am–6pm ET.' },
        { icon: '📚', title: 'Knowledge Base', desc: 'docs.insighthunter.com', detail: 'Step-by-step guides, videos, and FAQs for every feature.' }
      ] as channel}
        <div class="card text-center">
          <div class="text-4xl mb-4">{channel.icon}</div>
          <h3 class="font-bold text-sand-900 text-lg mb-1">{channel.title}</h3>
          <p class="text-accent font-medium text-sm mb-2">{channel.desc}</p>
          <p class="text-sand-500 text-sm">{channel.detail}</p>
        </div>
      {/each}
    </div>

    <!-- Contact form -->
    <div class="max-w-2xl mx-auto">
      <div class="card">
        <h2 class="text-2xl font-display font-bold text-sand-900 mb-6">Submit a Support Request</h2>

        {#if form?.success}
          <div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg mb-6">
            ✓ Your request has been submitted! We'll get back to you within 4 hours.
          </div>
        {/if}

        {#if form?.error}
          <div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-6">
            {form.error}
          </div>
        {/if}

        <form method="POST" action="?/submit" use:enhance class="space-y-5">
          <div class="grid sm:grid-cols-2 gap-4">
            <div>
              <label for="name" class="label">Full Name</label>
              <input id="name" name="name" type="text" class="input"
                     value={data.user?.fullName ?? ''} placeholder="Jane Smith" required />
            </div>
            <div>
              <label for="email" class="label">Email Address</label>
              <input id="email" name="email" type="email" class="input"
                     value={data.user?.email ?? ''} placeholder="jane@company.com" required />
            </div>
          </div>

          <div>
            <label for="subject" class="label">Subject</label>
            <input id="subject" name="subject" type="text" class="input"
                   placeholder="e.g. Can't access my dashboard" required />
          </div>

          <div>
            <label for="priority" class="label">Priority</label>
            <select id="priority" name="priority" class="input">
              <option value="low">Low — General question</option>
              <option value="normal" selected>Normal — Need help soon</option>
              <option value="high">High — Blocking my work</option>
            </select>
          </div>

          <div>
            <label for="message" class="label">Message</label>
            <textarea id="message" name="message" rows="5" class="input"
                      placeholder="Describe your issue in detail — the more info, the faster we can help." required />
          </div>

          <button type="submit" class="btn-primary w-full">Send Support Request →</button>
        </form>
      </div>
    </div>
  </div>
</section>

<!-- FAQ -->
<section class="section bg-white">
  <div class="container mx-auto max-w-3xl">
    <h2 class="text-3xl font-display font-bold text-sand-900 text-center mb-10">Quick Answers</h2>
    <div class="space-y-4">
      {#each [
        ['How do I connect my bank?', 'Go to Dashboard → Bookkeeping → Connect Account. We support CSV import for all banks and direct connect for major US institutions.'],
        ['How do I cancel my subscription?', 'Account → Subscription → Cancel Plan. Your data is retained for 30 days after cancellation.'],
        ['Can I upgrade or downgrade?', 'Yes, anytime from Account → Subscription. Upgrades are immediate; downgrades apply at your next billing date.'],
        ['Where is my data stored?', "All data is stored in Cloudflare's global network with encryption at rest and in transit. We are US-based."],
        ['Do you offer refunds?', "Yes — 30-day money-back guarantee on all paid plans. No questions asked."]
      ] as [q, a]}
        <details class="card cursor-pointer">
          <summary class="font-semibold text-sand-900 list-none flex justify-between">
            {q} <span class="text-accent">▾</span>
          </summary>
          <p class="mt-3 text-sand-600 text-sm">{a}</p>
        </details>
      {/each}
    </div>
  </div>
</section>
