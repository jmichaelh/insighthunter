<script lang="ts">
  import Badge from '$lib/components/shared/Badge.svelte';
  import { getFeaturesByTier } from '$lib/data/features';
  import type { AppDefinition, Tier } from '$lib/types/apps';

  export let app: AppDefinition;
  export let compact = false;
  export let showFeatures = true;

  const TIER_LABELS: Record<Tier, string> = {
    lite: 'Free',
    standard: 'Standard',
    pro: 'Pro',
    enterprise: 'Enterprise',
  };

  const TIER_BADGE_VARIANT: Record<Tier, 'tan' | 'success' | 'info' | 'warning'> = {
    lite: 'success',
    standard: 'info',
    pro: 'warning',
    enterprise: 'tan',
  };

  $: featurePreview = showFeatures && !app.comingSoon
    ? getFeaturesByTier(app.tier)
        .filter(f => !f.comingSoon)
        .slice(0, 3)
    : [];
</script>

<a
  href={app.comingSoon ? undefined : app.featurePage}
  class:app-card={true}
  class:app-card--compact={compact}
  class:app-card--coming-soon={app.comingSoon}
  aria-disabled={app.comingSoon ? 'true' : undefined}
  tabindex={app.comingSoon ? -1 : 0}
>
  {#if app.comingSoon}
    <div class="app-card__ribbon">Coming Soon</div>
  {/if}

  <div class="app-card__header">
    <div class="app-card__icon" aria-hidden="true">{app.icon}</div>
    <div class="app-card__meta">
      <h3 class="app-card__name">{app.name}</h3>
      <Badge variant={TIER_BADGE_VARIANT[app.tier]}>
        {TIER_LABELS[app.tier]}
      </Badge>
    </div>
  </div>

  <p class="app-card__desc">{app.description}</p>

  {#if featurePreview.length > 0}
    <ul class="app-card__features">
      {#each featurePreview as f}
        <li>
          <span class="app-card__check" aria-hidden="true">✓</span>
          {f.label}
        </li>
      {/each}
    </ul>
  {/if}

  <div class="app-card__footer">
    {#if app.comingSoon}
      <span class="app-card__cta app-card__cta--disabled">
        Notify Me
      </span>
    {:else}
      <span class="app-card__cta">
        Learn more →
      </span>
    {/if}
  </div>
</a>

<style>
  .app-card {
    position:        relative;
    display:         flex;
    flex-direction:  column;
    gap:             1rem;
    background:      #fff;
    border:          1px solid var(--color-border);
    border-radius:   var(--radius-lg);
    padding:         1.5rem;
    box-shadow:      var(--shadow-card);
    text-decoration: none;
    color:           inherit;
    overflow:        hidden;
    transition:      box-shadow 0.18s ease, transform 0.18s ease, border-color 0.18s ease;
    cursor:          pointer;
  }

  .app-card:hover:not(.app-card--coming-soon) {
    box-shadow:    var(--shadow-elevated);
    transform:     translateY(-3px);
    border-color:  var(--color-sand-300);
    text-decoration: none;
  }

  .app-card:focus-visible {
    outline:       2px solid var(--color-primary);
    outline-offset: 3px;
  }

  /* ── Compact variant ────────────────────────────────────── */
  .app-card--compact {
    padding: 1rem 1.25rem;
    gap:     0.75rem;
  }
  .app-card--compact .app-card__icon {
    font-size: 1.5rem;
  }
  .app-card--compact .app-card__name {
    font-size: 0.95rem;
  }

  /* ── Coming soon state ──────────────────────────────────── */
  .app-card--coming-soon {
    opacity: 0.72;
    cursor:  default;
    pointer-events: none;
  }

  /* ── Ribbon ─────────────────────────────────────────────── */
  .app-card__ribbon {
    position:     absolute;
    top:          14px;
    right:        -26px;
    background:   var(--color-sand-600);
    color:        #fff;
    font-size:    0.65rem;
    font-weight:  700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    padding:      4px 36px;
    transform:    rotate(35deg);
    transform-origin: top right;
    pointer-events: none;
    white-space:  nowrap;
  }

  /* ── Header ─────────────────────────────────────────────── */
  .app-card__header {
    display:     flex;
    align-items: flex-start;
    gap:         0.875rem;
  }

  .app-card__icon {
    font-size:   2.25rem;
    line-height: 1;
    flex-shrink: 0;
    margin-top:  2px;
  }

  .app-card__meta {
    display:        flex;
    flex-direction: column;
    gap:            5px;
  }

  .app-card__name {
    font-size:   1.05rem;
    font-weight: 700;
    line-height: 1.2;
    color:       var(--color-text);
  }

  /* ── Description ────────────────────────────────────────── */
  .app-card__desc {
    font-size:   0.875rem;
    color:       var(--color-text-muted);
    line-height: 1.6;
    flex:        1;
  }

  /* ── Feature bullets ────────────────────────────────────── */
  .app-card__features {
    list-style:     none;
    display:        flex;
    flex-direction: column;
    gap:            5px;
    border-top:     1px solid var(--color-border);
    padding-top:    0.875rem;
    margin-top:     auto;
  }

  .app-card__features li {
    display:     flex;
    align-items: center;
    gap:         6px;
    font-size:   0.8rem;
    color:       var(--color-text-muted);
  }

  .app-card__check {
    color:       var(--color-success);
    font-size:   0.75rem;
    flex-shrink: 0;
  }

  /* ── Footer CTA ─────────────────────────────────────────── */
  .app-card__footer {
    margin-top: auto;
    padding-top: 0.5rem;
  }

  .app-card__cta {
    font-size:   0.85rem;
    font-weight: 600;
    color:       var(--color-primary-dark);
    transition:  color 0.15s;
  }

  .app-card:hover .app-card__cta:not(.app-card__cta--disabled) {
    color: var(--color-sand-800);
  }

  .app-card__cta--disabled {
    color:  var(--color-text-muted);
    cursor: default;
  }
</style>
