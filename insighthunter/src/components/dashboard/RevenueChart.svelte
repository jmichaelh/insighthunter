<script lang="ts">
  // TODO: implement RevenueChart
</script>
<!-- STUB: RevenueChart island -->
<script lang="ts">
  import { onMount, afterUpdate } from 'svelte';
  import { api }                  from '@/lib/api';
  import Spinner                  from '@/components/shared/Spinner.svelte';

  interface DataPoint { month: string; revenue: number; expenses: number }

  type Period = '3m' | '6m' | '12m';

  let     DataPoint[] = [];
  let loading              = true;
  let error                = '';
  let period: Period       = '6m';
  let canvas: HTMLCanvasElement | null = null;

  async function load(p: Period) {
    loading = true; error = '';
    const res = await api.get<DataPoint[]>(`/dashboard/revenue-chart?period=${p}`);
    if ('data' in res) data = res.data;
    else error = res.error;
    loading = false;
  }

  onMount(() => load(period));

  afterUpdate(() => { if (!loading && data.length > 0 && canvas) drawChart(); });

  function drawChart() {
    if (!canvas) return;
    const ctx    = canvas.getContext('2d')!;
    const DPR    = window.devicePixelRatio || 1;
    const W      = canvas.clientWidth;
    const H      = canvas.clientHeight;
    canvas.width  = W * DPR;
    canvas.height = H * DPR;
    ctx.scale(DPR, DPR);

    const PAD    = { top: 16, right: 20, bottom: 40, left: 52 };
    const cW     = W - PAD.left - PAD.right;
    const cH     = H - PAD.top  - PAD.bottom;
    const maxVal = Math.max(...data.map(d => Math.max(d.revenue, d.expenses)), 1);
    const stepX  = cW / (data.length - 1 || 1);

    ctx.clearRect(0, 0, W, H);

    // Y-axis grid + labels
    const GRID_LINES = 4;
    for (let i = 0; i <= GRID_LINES; i++) {
      const y      = PAD.top + (cH / GRID_LINES) * i;
      const val    = maxVal * (1 - i / GRID_LINES);
      ctx.strokeStyle = '#e8ddd0';
      ctx.lineWidth   = 1;
      ctx.beginPath(); ctx.moveTo(PAD.left, y); ctx.lineTo(W - PAD.right, y); ctx.stroke();

      ctx.fillStyle  = '#9b8a72';
      ctx.font       = `11px Inter, system-ui, sans-serif`;
      ctx.textAlign  = 'right';
      ctx.fillText(val >= 1000 ? `$${(val/1000).toFixed(0)}k` : `$${val.toFixed(0)}`, PAD.left - 6, y + 4);
    }

    // Revenue fill area
    ctx.beginPath();
    data.forEach((d, i) => {
      const x = PAD.left + i * stepX;
      const y = PAD.top  + (1 - d.revenue / maxVal) * cH;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    ctx.lineTo(PAD.left + (data.length - 1) * stepX, PAD.top + cH);
    ctx.lineTo(PAD.left, PAD.top + cH);
    ctx.closePath();
    const grad = ctx.createLinearGradient(0, PAD.top, 0, PAD.top + cH);
    grad.addColorStop(0,   'rgba(155,138,114,0.25)');
    grad.addColorStop(1,   'rgba(155,138,114,0)');
    ctx.fillStyle = grad;
    ctx.fill();

    // Revenue line
    drawLine(ctx, data.map((d, i) => ({
      x: PAD.left + i * stepX,
      y: PAD.top  + (1 - d.revenue  / maxVal) * cH,
    })), '#9b8a72', 2.5);

    // Expenses line (dashed)
    ctx.setLineDash([5, 4]);
    drawLine(ctx, data.map((d, i) => ({
      x: PAD.left + i * stepX,
      y: PAD.top  + (1 - d.expenses / maxVal) * cH,
    })), '#c0392b', 2);
    ctx.setLineDash([]);

    // Dots + X labels
    data.forEach((d, i) => {
      const x  = PAD.left + i * stepX;
      const yR = PAD.top  + (1 - d.revenue  / maxVal) * cH;
      const yE = PAD.top  + (1 - d.expenses / maxVal) * cH;

      // Revenue dot
      ctx.beginPath();
      ctx.arc(x, yR, 4, 0, Math.PI * 2);
      ctx.fillStyle   = '#9b8a72';
      ctx.fill();

      // Expense dot
      ctx.beginPath();
      ctx.arc(x, yE, 4, 0, Math.PI * 2);
      ctx.fillStyle   = '#c0392b';
      ctx.fill();

      // X label
      ctx.fillStyle   = '#9b8a72';
      ctx.font        = '11px Inter, system-ui, sans-serif';
      ctx.textAlign   = 'center';
      ctx.fillText(d.month, x, H - PAD.bottom + 16);
    });
  }

  function drawLine(
    ctx:    CanvasRenderingContext2D,
    points: { x: number; y: number }[],
    color:  string,
    width:  number,
  ) {
    if (points.length < 2) return;
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    // Smooth cubic bezier
    for (let i = 1; i < points.length; i++) {
      const prev = points[i - 1];
      const curr = points[i];
      const cpX  = (prev.x + curr.x) / 2;
      ctx.bezierCurveTo(cpX, prev.y, cpX, curr.y, curr.x, curr.y);
    }
    ctx.strokeStyle = color;
    ctx.lineWidth   = width;
    ctx.lineJoin    = 'round';
    ctx.lineCap     = 'round';
    ctx.stroke();
  }
</script>

<div class="rev-chart">
  <!-- Header -->
  <div class="rev-chart__header">
    <h3 class="panel-title">Revenue vs Expenses</h3>
    <div class="rev-chart__controls">
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
  <div class="rev-legend">
    <span><span class="rev-legend__line rev-legend__line--revenue" /> Revenue</span>
    <span><span class="rev-legend__line rev-legend__line--expenses" /> Expenses</span>
  </div>

  <!-- Canvas -->
  {#if loading}
    <div class="rev-loading"><Spinner /></div>
  {:else if error}
    <p class="rev-error">{error}</p>
  {:else if data.length === 0}
    <div class="rev-empty">No revenue data yet. Upload transactions to get started.</div>
  {:else}
    <canvas bind:this={canvas} class="rev-canvas" aria-label="Revenue vs Expenses chart" />
  {/if}
</div>

<style>
  .rev-chart {
    background:     #fff;
    border:         1px solid var(--color-border);
    border-radius:  var(--radius-lg);
    padding:        1.25rem;
    box-shadow:     var(--shadow-card);
    display:        flex;
    flex-direction: column;
    gap:            0.75rem;
  }

  .rev-chart__header {
    display:         flex;
    justify-content: space-between;
    align-items:     center;
  }

  .rev-chart__controls { display: flex; gap: 4px; }

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

  .rev-legend {
    display:     flex;
    gap:         16px;
    font-size:   0.78rem;
    color:       var(--color-text-muted);
    align-items: center;
  }
  .rev-legend span { display: flex; align-items: center; gap: 6px; }

  .rev-legend__line {
    display:       inline-block;
    width:         24px;
    height:        2px;
    border-radius: 1px;
  }
  .rev-legend__line--revenue  { background: #9b8a72; }
  .rev-legend__line--expenses { background: #c0392b; border-top: 2px dashed #c0392b; height: 0; }

  .rev-canvas {
    width:  100%;
    height: 240px;
    display: block;
  }

  .rev-loading { display: flex; justify-content: center; padding: 3rem 0; }
  .rev-error   { color: var(--color-danger); font-size: 0.875rem; }
  .rev-empty   {
    display:         flex;
    justify-content: center;
    align-items:     center;
    padding:         3rem;
    color:           var(--color-text-muted);
    font-size:       0.875rem;
    text-align:      center;
  }
</style>
