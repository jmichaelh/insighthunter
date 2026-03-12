<script lang="ts">
  // TODO: implement ForecastWidget
</script>
<!-- STUB: ForecastWidget island -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { api }     from '@/lib/api';
  import Spinner     from '@/components/shared/Spinner.svelte';

  interface ForecastPoint {
    month:      string;
    projected:  number;
    actual?:    number;
    confidence: number;   // 0–1
  }

  interface ForecastSummary {
    runway:         number;    // months
    burnRate:       number;    // monthly avg
    endingCash:     number;    // projected 90-day
    riskLevel:      'low' | 'medium' | 'high';
    points:         ForecastPoint[];
  }

  let     ForecastSummary | null = null;
  let loading                         = true;
  let error                           = '';

  onMount(async () => {
    const res = await api.get<ForecastSummary>('/forecast/summary');
    if ('data' in res) data = res.data;
    else error = res.error;
    loading = false;
  });

  const RISK_COLOR: Record<string, string> = {
    low:    'var(--color-success)',
    medium: 'var(--color-warning)',
    high:   'var(--color-danger)',
  };
  const RISK_LABEL: Record<string, string> = {
    low:    '✅ Low Risk',
    medium: '⚠️ Medium Risk',
    high:   '🔴 High Risk',
  };

  function fmt(n: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency', currency: 'USD', maximumFractionDigits: 0,
    }).format(n);
  }

  $: maxVal = data
    ? Math.max(...data.points.map(p => Math.max(p.projected, p.actual ?? 0)), 1)
    : 1;
</script>

<div class="forecast-widget">
  <div class="forecast-widget__header">
    <h3 class="panel-title">90-Day Forecast</h3>
    <a href="/dashboard/forecast" class="forecast-widget__link">Full forecast →</a>
  </div>

  {#if loading}
    <div class="forecast-loading"><Spinner size="sm" /></div>
  {:else if error}
    <p class="forecast-error">{error}</p>
  {:else if data}

    <!-- KPI strip -->
    <div class="forecast-kpis">
      <div class="forecast-kpi">
        <span class="forecast-kpi__label">Runway</span>
        <strong class="forecast-kpi__value">{data.runway} mo</strong>
      </div>
      <div class="forecast-kpi">
        <span class="forecast-kpi__label">Burn Rate</span>
        <strong class="forecast-kpi__value">{fmt(data.burnRate)}/mo</strong>
      </div>
      <div class="forecast-kpi">
        <span class="forecast-kpi__label">90-Day Cash</span>
        <strong class="forecast-kpi__value">{fmt(data.endingCash)}</strong>
      </div>
      <div class="forecast-kpi">
        <span class="forecast-kpi__label">Risk</span>
        <strong
          class="forecast-kpi__value"
          style="color:{RISK_COLOR[data.riskLevel]}"
        >
          {RISK_LABEL[data.riskLevel]}
        </strong>
      </div>
    </div>

    <!-- Mini bar chart — projected vs actual -->
    <div class="forecast-chart">
      {#each data.points as pt}
        {@const projH  = (pt.projected / maxVal) * 90}
        {@const actH   = ((pt.actual ?? 0) / maxVal) * 90}
        <div class="forecast-col">
          <div class="forecast-bar-wrap">
            {#if pt.actual !== undefined}
              <div
                class="forecast-bar forecast-bar--actual"
                style="height:{actH}px"
                title="Actual: {fmt(pt.actual)}"
              />
            {/if}
            <div
              class="forecast-bar forecast-bar--projected"
              style="height:{projH}px; opacity:{0.4 + pt.confidence * 0.6}"
              title="Projected: {fmt(pt.projected)} ({Math.round(pt.confidence * 100)}% confidence)"
            />
          </div>
          <span class="forecast-col__label">{pt.month}</span>
        </div>
      {/each}
    </div>

    <!-- Confidence note -->
    <p class="forecast-note">
      📌 Projections based on trailing 90 days. Confidence intervals shown by bar opacity.
    </p>

  {:else}
    <div class="forecast-empty">
      Connect a bank account or upload transactions to generate your forecast.
      <a href="/dashboard/bookkeeping" class="btn btn--primary btn--sm" style="margin-top:12px">
        Connect Account
      </a>
    </div>
  {/if}
</div>

<style>
  .forecast-widget {
    background:     #fff;
    border:         1px solid var(--color-border);
    border-radius:  var(--radius-lg);
    padding:        1.25rem;
    box-shadow:     var(--shadow-card);
    display:        flex;
    flex-direction: column;
    gap:            1rem;
  }

  .forecast-widget__header {
    display:         flex;
    justify-content: space-between;
    align-items:     center;
  }
  .forecast-widget__link {
    font-size:       0.8rem;
    color:           var(--color-text-muted);
    text-decoration: none;
  }
  .forecast-widget__link:hover { color: var(--color-primary-dark); }

  .forecast-loading, .forecast-empty {
    display:        flex;
    flex-direction: column;
    align-items:    center;
    padding:        2rem 0;
    color:          var(--color-text-muted);
    font-size:      0.875rem;
    text-align:     center;
    gap:            8px;
  }

  .forecast-error { color: var(--color-danger); font-size: 0.875rem; }

  /* KPI strip */
  .forecast-kpis {
    display:  grid;
    grid-template-columns: repeat(4, 1fr);
    gap:      8px;
  }
  @media (max-width: 600px) {
    .forecast-kpis { grid-template-columns: repeat(2, 1fr); }
  }

  .forecast-kpi {
    background:    var(--color-sand-50);
    border:        1px solid var(--color-border);
    border-radius: var(--radius-md);
    padding:       10px;
    display:       flex;
    flex-direction: column;
    gap:           3px;
  }
  .forecast-kpi__label { font-size: 0.7rem; color: var(--color-text-muted); text-transform: uppercase; letter-spacing: 0.05em; }
  .forecast-kpi__value { font-size: 0.95rem; font-weight: 700; }

  /* Mini chart */
  .forecast-chart {
    display:         flex;
    align-items:     flex-end;
    justify-content: space-between;
    gap:             6px;
    min-height:      100px;
    padding-top:     0.5rem;
  }

  .forecast-col {
    display:        flex;
    flex-direction: column;
    align-items:    center;
    gap:            4px;
    flex:           1;
  }

  .forecast-bar-wrap {
    display:     flex;
    align-items: flex-end;
    gap:         2px;
  }

  .forecast-bar {
    width:         12px;
    border-radius: 3px 3px 0 0;
    min-height:    3px;
    transition:    height 0.4s ease;
  }
  .forecast-bar--actual    { background: var(--color-primary); }
  .forecast-bar--projected { background: var(--color-sand-400); }

  .forecast-col__label {
    font-size:   0.7rem;
    color:       var(--color-text-muted);
    white-space: nowrap;
  }

  .forecast-note {
    font-size:  0.75rem;
    color:      var(--color-text-muted);
    line-height: 1.4;
    border-top: 1px solid var(--color-border);
    padding-top: 0.75rem;
  }
</style>
