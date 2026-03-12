<script lang="ts">
  import type { Feature } from '$lib/data/features';
  import Badge from '$lib/components/shared/Badge.svelte';

  export let features: Feature[];
  export let columns: 2 | 3 | 4 = 3;
</script>

<div class={`feature-grid feature-grid--cols-${columns}`}>
  {#each features as f}
    <div class="feature-item" class:feature-item--soon={f.comingSoon}>
      <div class="feature-item__top">
        <h4 class="feature-item__label">{f.label}</h4>
        {#if f.comingSoon}
          <Badge variant="tan">Soon</Badge>
        {/if}
      </div>
      <p class="feature-item__desc">{f.description}</p>
    </div>
  {/each}
</div>

<style>
  .feature-grid {
    display:               grid;
    gap:                   1rem;
    margin-top:            2rem;
  }
  .feature-grid--cols-2 { grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); }
  .feature-grid--cols-3 { grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); }
  .feature-grid--cols-4 { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }

  .feature-item {
    background:    #fff;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding:       1.25rem;
    box-shadow:    var(--shadow-card);
    display:       flex;
    flex-direction: column;
    gap:           0.5rem;
    transition:    box-shadow 0.15s, transform 0.15s;
  }
  .feature-item:hover {
    box-shadow: var(--shadow-elevated);
    transform:  translateY(-2px);
  }
  .feature-item--soon { opacity: 0.7; }

  .feature-item__top {
    display:     flex;
    align-items: center;
    gap:         8px;
    flex-wrap:   wrap;
  }

  .feature-item__label {
    font-size:   0.9rem;
    font-weight: 700;
    color:       var(--color-text);
    flex:        1;
  }

  .feature-item__desc {
    font-size:   0.825rem;
    color:       var(--color-text-muted);
    line-height: 1.6;
  }
</style>
