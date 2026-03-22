<!-- src/components/dashboard/KPICard.svelte -->
<script lang="ts">
  import type { TierSlug } from '../../data/pricing';
  import { canAccess } from '../../data/features';
  import Badge from '../shared/Badge.astro';

  export let kpiKey: string;
  export let label: string;
  export let value: string | number;
  export let unit: string = '';
  export let trend: 'up' | 'down' | 'flat' = 'flat';
  export let index: number = 0; // position in KPI list (0-based)
  export let userTier: TierSlug = 'lite';

  const LITE_KPI_LIMIT = 3;

  // Lite tier: only first 3 KPIs are visible; the rest are blurred + locked
  $: isLocked =
    userTier === 'lite' &&
    !canAccess(userTier, 'kpi_dashboard_full') &&
    index >= LITE_KPI_LIMIT;

  const trendIcon = { up: '↑', down: '↓', flat: '→' } as const;
  const trendColor = { up: 'color-green', down: 'color-red', flat: 'color-muted' } as const;

  async function firePaywallEvent() {
    if (!isLocked) return;
    try {
      const token = document.cookie.match(/ih_session=([^;]+)/)?.[1];
      await fetch('/api/lite/paywall-hit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ feature: 'kpi_dashboard_full' }),
      });
    } catch (_) {
      // Non-critical — fire and forget
    }
  }
</script>

<div
  class="kpi-card"
  class:locked={isLocked}
  on:click={isLocked ? firePaywallEvent : undefined}
  role={isLocked ? 'button' : 'article'}
  aria-label={isLocked ? `${label} — upgrade to unlock` : label}
  tabindex={isLocked ? 0 : -1}
>
  {#if isLocked}
    <div class="lock-overlay">
      <span class="lock-icon" aria-hidden="true">🔒</span>
      <p class="lock-message">Upgrade to Standard</p>
      <a href="/dashboard/upgrade?feature=kpi_dashboard_full" class="upgrade-link">
        Unlock All KPIs →
      </a>
    </div>
  {/if}

  <div class="kpi-inner" class:blurred={isLocked} aria-hidden={isLocked}>
    <span class="kpi-label">{label}</span>
    <span class="kpi-value">
      {typeof value === 'number' ? value.toLocaleString() : value}
      {#if unit}<span class="kpi-unit">{unit}</span>{/if}
    </span>
    <span class="kpi-trend {trendColor[trend]}">
      {trendIcon[trend]}
    </span>
  </div>
</div>

<style lang="scss">
  .kpi-card {
    position: relative;
    background: var(--surface-1);
    border: 1px solid var(--border-subtle);
    border-radius: 0.75rem;
    padding: 1.25rem 1.5rem;
    min-width: 160px;
    transition: box-shadow 0.15s ease;

    &:not(.locked):hover {
      box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
    }

    &.locked {
      cursor: pointer;
      border-color: var(--border-muted);
    }
  }

  .kpi-inner {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
  }

  .blurred {
    filter: blur(6px);
    user-select: none;
    pointer-events: none;
  }

  .kpi-label {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--text-muted);
  }

  .kpi-value {
    font-size: 1.75rem;
    font-weight: 700;
    color: var(--text-primary);
    line-height: 1;
  }

  .kpi-unit {
    font-size: 0.875rem;
    font-weight: 400;
    color: var(--text-muted);
    margin-left: 0.2em;
  }

  .kpi-trend {
    font-size: 0.875rem;
    font-weight: 600;
    &.color-green { color: var(--color-success); }
    &.color-red   { color: var(--color-danger); }
    &.color-muted { color: var(--text-muted); }
  }

  .lock-overlay {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
    z-index: 2;
    border-radius: 0.75rem;
    background: rgba(var(--surface-1-rgb), 0.7);
    backdrop-filter: blur(1px);
    text-align: center;
    padding: 1rem;
  }

  .lock-icon {
    font-size: 1.4rem;
  }

  .lock-message {
    font-size: 0.75rem;
    font-weight: 600;
    color: var(--text-secondary);
    margin: 0;
  }

  .upgrade-link {
    font-size: 0.7rem;
    font-weight: 700;
    color: var(--color-accent);
    text-decoration: none;
    &:hover { text-decoration: underline; }
  }
</style>
