<script lang="ts">
  export let title: string;
  export let sub: string | undefined = undefined;
  export let primaryLabel: string;
  export let primaryHref: string;
  export let secondaryLabel: string | undefined = undefined;
  export let secondaryHref: string | undefined = undefined;
</script>

<section class="feature-cta">
  <div class="feature-cta__inner">
    <h2>{title}</h2>
    {#if sub}
      <p>{sub}</p>
    {/if}
    <div class="feature-cta__btns">
      <a href={primaryHref} class="btn btn--primary btn--lg">{primaryLabel}</a>
      {#if secondaryLabel && secondaryHref}
        <a href={secondaryHref} class="btn btn--ghost-light btn--lg">{secondaryLabel}</a>
      {/if}
    </div>
  </div>
</section>

<style>
  .feature-cta {
    background:  var(--color-sand-800);
    color:       #fff;
    padding:     5rem 1.5rem;
    text-align:  center;
  }
  .feature-cta__inner { max-width: 580px; margin: auto; }
  .feature-cta h2 { font-size: 2.25rem; font-weight: 800; margin-bottom: 0.75rem; }
  .feature-cta p  { color: var(--color-sand-300); font-size: 1rem; margin-bottom: 2rem; line-height: 1.6; }
  .feature-cta__btns { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }

  .btn--ghost-light {
    background: transparent;
    border:     1px solid rgba(255,255,255,0.3);
    color:      #fff;
  }
  .btn--ghost-light:hover { background: rgba(255,255,255,0.1); }
</style>
