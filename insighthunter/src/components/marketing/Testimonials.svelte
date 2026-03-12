<script lang="ts">
  export let testimonials: { quote: string; author: string }[];
</script>

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
