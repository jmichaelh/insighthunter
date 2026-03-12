<script lang="ts">
  // TODO: implement CashFlowChart
</script>
<!-- STUB: CashFlowChart island -->
<script lang="ts">
  import { onMount }   from 'svelte';
  import { api }       from '@/lib/api';
  import Spinner       from '@/components/shared/Spinner.svelte';

  interface FlowPoint {
    month:   string;
    inflow:  number;
    outflow: number;
    net:     number;
  }

  type Period = '3m' | '6m' | '12m';

  let     FlowPoint[] = [];
  let loading              = true;
  let error                = '';
  let period: Period       = '6m';

  async function load(p: Period) {
    loading = true;
    error   = '';
    const res = await api.get<FlowPoint[]>(`/dashboard/cash-flow-chart?period=${p}`);
    if ('data' in res) {
      data = res.data;
    } else {
      error = res.error;
    }
    loading = false;
  }

  onMount(() => load(period));

  $: maxVal = Math.max(...data.map(d => Math.max(d.inflow, d.outflow)), 1);

  function barHeight(val: number, max: number): number {
    return Math.max((val / max) * 120, 3);
  }

  function fmt(n: number): string {
    const abs = Math.abs(n);
    const str = abs >= 1000
      ? `$${(abs / 1000).toFixed(1)}k`
      : `$${abs.toFixed(0)}`;
    return n < 0 ? `(${str})` : str;
  }
</script>

<div class="cf-chart">
  <!-- Header -->
  <div class="cf-chart__header">
    <h3 class="panel-title">Cash Flow</h3>
    <div class="cf-chart__controls">
      {#each (['3m', '6m', '12m'] as Period[]) as p}
        <button
          class="period-btn"
          class:active={period === p}
          on:click={() => { period = p; load(p); }}
        >
          {p}
        </button>
      {/each}
    </div>
  </div>

  <!-- Legend -->
  <div class="cf-legend">
    <span class="cf-legend__dot cf-legend__dot--inflow"  /> Inflow
    <span class="cf-legend__dot cf-legend__dot--outflow" /> Outflow
  </div>

  <!-- Chart body -->
  {#if loading}
    <div class="cf-loading"><Spinner size="sm" /></div>
  {:else if error}
    <p class="cf-error">{error}</p>
  {:else if data.length === 0}
    <div class="cf-empty">No cash flow data yet.</div>
  {:else}
    <div class="cf-bars">
      {#each data as point}
        <div class="cf-group">
          <!-- Bars -->
          <div class="cf-bar-pair">
            <div
              class="cf-bar cf-bar--inflow"
              style="height:{barHeight(point.inflow, maxVal)}px"
              title="Inflow: {fmt(point.inflow)}"
            />
            <div
              class="cf-bar cf-bar--outflow"
              style="height:{barHeight(point.outflow, maxVal)}px"
              title="Outflow: {fmt(point.outflow)}"
            />
          </div>
          <!-- Month label -->
          <span class="cf-group__month">{point.month}</span>
          <!-- Net -->
          <span
            class="cf-group__net"
            class:positive={point.net >= 0}
            class:negative={point.net < 0}
          >
            {fmt(point.net)}
          </span>
        </div>
      {/each}
    </div>

    <!-- Summary row -->
    <div class="cf-summary">
      {@const totalNet = data.reduce((acc, d) => acc + d.net, 0)}
      <span>Period Net:</span>
      <strong
        class:positive={totalNet >= 0}
        class:negative={totalNet < 0}
      >
        {fmt(totalNet)}
      </strong>
    </div>
  {/if}
</div>

<style>
  .cf-chart {
    background:     #fff;
    border:         1px solid var(--color-border);
    border-radius:  var(--radius-lg);
    padding:        1.25rem;
    box-shadow:     var(--shadow-card);
    display:        flex;
    flex-direction: column;
    gap:            0.875rem;
  }

  .cf-chart__header {
    display:         flex;
    justify-content: space-between;
    align-items:     center;
  }

  .cf-chart__controls {
    display: flex;
    gap:     4px;
  }

  .period-btn {
    padding:       4px 10px;
    font-size:     0.75rem;
    font-weight:   600;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-sm);
    background:    transparent;
    cursor:        pointer;
    color:         var(--color-text-muted);
    transition:    all 0.12s;
  }
  .period-btn:hover  { background: var(--color-sand-100); color: var(--color-text); }
  .period-btn.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }

  .cf-legend {
    display:     flex;
    align-items: center;
    gap:         12px;
    font-size:   0.78rem;
    color:       var(--color-text-muted);
  }
  .cf-legend__dot {
    display:       inline-block;
    width:         10px;
    height:        10px;
    border-radius: 2px;
    margin-right:  3px;
  }
  .cf-legend__dot--inflow  { background: var(--color-success); }
  .cf-legend__dot--outflow { background: var(--color-danger); opacity: 0.75; }

  .cf-loading, .cf-empty {
    display:         flex;
    justify-content: center;
    align-items:     center;
    padding:         2.5rem 0;
    color:           var(--color-text-muted);
    font-size:       0.875rem;
  }
  .cf-error { color: var(--color-danger); font-size: 0.875rem; }

  .cf-bars {
    display:         flex;
    align-items:     flex-end;
    justify-content: space-between;
    gap:             6px;
    padding-top:     0.5rem;
    min-height:      140px;
  }

  .cf-group {
    display:        flex;
    flex-direction: column;
    align-items:    center;
    gap:            4px;
    flex:           1;
  }

  .cf-bar-pair {
    display:     flex;
    align-items: flex-end;
    gap:         3px;
  }

  .cf-bar {
    width:         14px;
    border-radius: 3px 3px 0 0;
    transition:    height 0.4s ease;
    min-height:    3px;
  }
  .cf-bar--inflow  { background: var(--color-success); }
  .cf-bar--outflow { background: var(--color-danger); opacity: 0.75; }

  .cf-group__month {
    font-size:   0.7rem;
    color:       var(--color-text-muted);
    white-space: nowrap;
  }

  .cf-group__net {
    font-size:   0.7rem;
    font-weight: 600;
    white-space: nowrap;
  }

  .cf-summary {
    display:       flex;
    justify-content: flex-end;
    align-items:   center;
    gap:           8px;
    font-size:     0.8rem;
    color:         var(--color-text-muted);
    border-top:    1px solid var(--color-border);
    padding-top:   0.75rem;
  }
  .cf-summary strong { font-size: 0.9rem; }

  .positive { color: var(--color-success); }
  .negative { color: var(--color-danger); }
</style>
