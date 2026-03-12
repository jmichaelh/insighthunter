<script lang="ts">
  import { onMount }     from 'svelte';
  import { api }         from '@/lib/api';
  import type { KPISummary } from '@/types/api';

  export let metric: keyof KPISummary;

  const CONFIG: Record<keyof KPISummary, {
    label:  string;
    icon:   string;
    format: 'currency' | 'months' | 'percent';
    good?:  'high' | 'low';
  }> = {
    revenue:    { label: 'Revenue',      icon: '💰', format: 'currency', good: 'high' },
    expenses:   { label: 'Expenses',     icon: '📤', format: 'currency', good: 'low'  },
    netIncome:  { label: 'Net Income',   icon: '📈', format: 'currency', good: 'high' },
    cashOnHand: { label: 'Cash on Hand', icon: '🏦', format: 'currency', good: 'high' },
    burnRate:   { label: 'Burn Rate',    icon: '🔥', format: 'currency', good: 'low'  },
    runway:     { label: 'Runway',       icon: '🛣️', format: 'months',   good: 'high' },
    period:     { label: 'Period',       icon: '📅', format: 'currency'              },
  };

  const cfg = CONFIG[metric];

  let value:   number | string = 0;
  let delta:   number          = 0;      // % change vs prior period
  let loading                  = true;

  onMount(async () => {
    const res = await api.get<KPISummary & { deltas: Partial<Record<keyof KPISummary, number>> }>(
      '/dashboard/kpi'
    );
    if ('data' in res) {
      value = res.data[metric] as number;
      delta = res.data.deltas?.[metric] ?? 0;
    }
    loading = false;
  });

  function formatValue(v: number | string): string {
    if (typeof v !== 'number') return String(v);
    if (cfg.format === 'months')  return `${v} mo`;
    if (cfg.format === 'percent') return `${v.toFixed(1)}%`;
    return new Intl.NumberFormat('en-US', {
      style:                 'currency',
      currency:              'USD',
      maximumFractionDigits: 0,
    }).format(v);
  }

  $: deltaPositive = delta >= 0;
  $: deltaColor = (() => {
    if (delta === 0) return 'var(--color-text-muted)';
    if (!cfg.good)   return 'var(--color-text-muted)';
    const good = (cfg.good === 'high' && deltaPositive) || (cfg.good === 'low' && !deltaPositive);
    return good ? 'var(--color-success)' : 'var(--color-danger)';
  })();
</script>

<div class="kpi-card">
  <div class="kpi-card__top">
    <span class="kpi-card__icon" aria-hidden="true">{cfg.icon}</span>
    <span class="kpi-card__label">{cfg.label}</span>
  </div>

  {#if loading}
    <div class="kpi-card__skeleton" aria-label="Loading {cfg.label}" />
  {:else}
    <p class="kpi-card__value">{formatValue(value as number)}</p>

    {#if delta !== 0}
      <div class="kpi-card__delta" style="color:{deltaColor}">
        <span aria-hidden="true">{deltaPositive ? '▲' : '▼'}</span>
        {Math.abs(delta).toFixed(1)}% vs last period
      </div>
    {/if}
  {/if}
</div>

<style>
  .kpi-card {
    background:    #fff;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding:       1.25rem;
    box-shadow:    var(--shadow-card);
    display:       flex;
    flex-direction: column;
    gap:           6px;
    transition:    box-shadow 0.15s;
  }
  .kpi-card:hover { box-shadow: var(--shadow-elevated); }

  .kpi-card__top {
    display:     flex;
    align-items: center;
    gap:         6px;
  }

  .kpi-card__icon { font-size: 1rem; }

  .kpi-card__label {
    font-size:      0.75rem;
    color:          var(--color-text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-weight:    600;
  }

  .kpi-card__value {
    font-size:   1.9rem;
    font-weight: 800;
    color:       var(--color-text);
    line-height: 1.1;
    font-variant-numeric: tabular-nums;
  }

  .kpi-card__delta {
    font-size:   0.78rem;
    font-weight: 600;
    display:     flex;
    align-items: center;
    gap:         3px;
  }

  .kpi-card__skeleton {
    height:        2.2rem;
    border-radius: var(--radius-sm);
    background:    var(--color-sand-100);
    animation:     pulse 1.4s ease-in-out infinite;
    margin-top:    4px;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50%       { opacity: 0.4; }
  }
</style>
