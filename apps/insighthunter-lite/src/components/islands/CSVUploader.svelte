<!-- apps/insighthunter-lite/src/components/islands/CSVUploader.svelte -->
<script lang="ts">
  type State = 'idle' | 'uploading' | 'done' | 'error';

  interface Metrics {
    currentCash: number;
    monthlyBurn: number;
    runway: number;
    totalIncome: number;
    totalExpenses: number;
    byCategory: Record<string, number>;
    forecast: { month: string; income: number; expenses: number; net: number }[];
  }

  interface UploadResult {
    uploadId: string;
    reportId: string;
    metrics: Metrics;
    aiSummary: string;
  }

  let state: State     = 'idle';
  let result: UploadResult | null = null;
  let errorMsg         = '';
  let dragOver         = false;
  let fileInput: HTMLInputElement;

  const fmt = (n: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);

  async function handleFile(file: File) {
    if (!file.name.endsWith('.csv')) { errorMsg = 'Please select a .csv file.'; state = 'error'; return; }
    state = 'uploading'; errorMsg = ''; result = null;

    const fd = new FormData();
    fd.append('csvFile', file); // keep field name "csvFile" — matches original form + API handler

    try {
      const res  = await fetch('/api/upload', { method: 'POST', body: fd });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Upload failed');
      result = data as UploadResult;
      state  = 'done';
    } catch (e) {
      errorMsg = e instanceof Error ? e.message : 'Unknown error';
      state    = 'error';
    }
  }

  const onInput  = (e: Event) => { const f = (e.target as HTMLInputElement).files?.[0]; if (f) handleFile(f); };
  const onDrop   = (e: DragEvent) => { e.preventDefault(); dragOver = false; const f = e.dataTransfer?.files[0]; if (f) handleFile(f); };
  const reset    = () => { state = 'idle'; result = null; errorMsg = ''; if (fileInput) fileInput.value = ''; };
</script>

<!-- ── Drop Zone ── -->
{#if state === 'idle' || state === 'error'}
  <!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
  <div
    class="drop-zone" class:over={dragOver}
    role="button" tabindex="0"
    on:dragover|preventDefault={() => dragOver = true}
    on:dragleave={() => dragOver = false}
    on:drop={onDrop}
    on:click={() => fileInput.click()}
    on:keydown={e => e.key === 'Enter' && fileInput.click()}
  >
    <span class="icon">📂</span>
    <p class="title">Drop your CSV here or <span class="link">browse</span></p>
    <p class="hint">Bank export, QuickBooks, Wave — needs Date and Amount columns</p>
    <input bind:this={fileInput} type="file" accept=".csv" class="sr-only" on:change={onInput} />
  </div>

  {#if state === 'error'}
    <div class="alert">⚠️ {errorMsg} <button on:click={reset}>Try again</button></div>
  {/if}
{/if}

<!-- ── Loading ── -->
{#if state === 'uploading'}
  <div class="loading">
    <div class="spinner"></div>
    <p>Parsing transactions and generating insights…</p>
  </div>
{/if}

<!-- ── Results ── mirror of original Dashboard component metrics grid ── -->
{#if state === 'done' && result}
  {@const m = result.metrics}

  <div class="results">
    <!-- Metric cards — same 3 KPIs as original: currentCash, monthlyBurn, runway -->
    <div class="metrics">
      <div class="metric-card">
        <div class="label">Current Cash</div>
        <div class="value" class:positive={m.currentCash >= 0} class:negative={m.currentCash < 0}>
          {fmt(m.currentCash)}
        </div>
      </div>
      <div class="metric-card">
        <div class="label">Monthly Burn</div>
        <div class="value negative">{fmt(Math.abs(m.monthlyBurn))}</div>
      </div>
      <div class="metric-card">
        <div class="label">Runway</div>
        <div class="value" class:positive={m.runway > 6} class:warning={m.runway > 0 && m.runway <= 6} class:negative={m.runway === 0}>
          {m.runway > 0 ? `${m.runway.toFixed(1)} months` : 'N/A'}
        </div>
      </div>
      <div class="metric-card">
        <div class="label">Net P&L</div>
        <div class="value" class:positive={m.totalIncome - m.totalExpenses >= 0} class:negative={m.totalIncome - m.totalExpenses < 0}>
          {fmt(m.totalIncome - m.totalExpenses)}
        </div>
      </div>
    </div>

    <!-- AI Summary -->
    {#if result.aiSummary}
      <div class="ai-card">
        <h3>🤖 CFO Insights</h3>
        <pre>{result.aiSummary}</pre>
      </div>
    {/if}

    <!-- Category Breakdown -->
    <div class="card">
      <h3>Spending by Category</h3>
      <ul class="cat-list">
        {#each Object.entries(m.byCategory).sort((a, b) => b[1] - a[1]) as [cat, amt]}
          <li>
            <span class="cat-name">{cat}</span>
            <div class="bar-track">
              <div class="bar" style="width:{Math.round((amt / m.totalExpenses) * 100)}%"></div>
            </div>
            <span class="cat-amt">{fmt(amt)}</span>
          </li>
        {/each}
      </ul>
    </div>

    <!-- 3-Month Forecast -->
    <div class="card">
      <h3>3-Month Forecast</h3>
      <table>
        <thead><tr><th>Period</th><th>Income</th><th>Expenses</th><th>Net</th></tr></thead>
        <tbody>
          {#each m.forecast as row}
            <tr>
              <td>{row.month}</td>
              <td class="pos">{fmt(row.income)}</td>
              <td class="neg">{fmt(row.expenses)}</td>
              <td class:pos={row.net >= 0} class:neg={row.net < 0}>{fmt(row.net)}</td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>

    <div class="actions">
      <a href="/" class="btn">← Back to Dashboard</a>
      <button class="btn outline" on:click={reset}>Upload Another</button>
    </div>
  </div>
{/if}

<style>
  .drop-zone   { border:2px dashed #d1d5db; border-radius:12px; padding:3rem 2rem; text-align:center; cursor:pointer; transition:.2s; }
  .drop-zone:hover, .over { border-color:#007aff; background:#f0f7ff; }
  .icon        { font-size:2.5rem; }
  .title       { font-size:1.1rem; font-weight:600; margin:.5rem 0 .25rem; }
  .hint        { font-size:.85rem; color:#6b7280; margin:0; }
  .link        { color:#007aff; text-decoration:underline; }
  .sr-only     { position:absolute; width:1px; height:1px; overflow:hidden; clip:rect(0,0,0,0); }

  .loading     { display:flex; flex-direction:column; align-items:center; gap:1rem; padding:3rem; }
  .spinner     { width:36px; height:36px; border:3px solid #e5e7eb; border-top-color:#007aff; border-radius:50%; animation:spin .8s linear infinite; }
  @keyframes spin { to { transform:rotate(360deg); } }

  .alert       { background:#fef2f2; color:#b91c1c; border:1px solid #fca5a5; border-radius:8px; padding:.75rem 1rem; margin-top:1rem; display:flex; align-items:center; gap:.75rem; }
  .alert button{ background:none; border:none; cursor:pointer; text-decoration:underline; color:inherit; font-size:.8rem; margin-left:auto; }

  /* Mirrors original .metrics / .metric-card from index.tsx */
  .metrics     { display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:1rem; margin-bottom:1.5rem; }
  .metric-card { background:#f7f7f7; padding:1.5rem; border-radius:8px; text-align:center; }
  .label       { font-size:1rem; font-weight:500; margin-bottom:.5rem; }
  .value       { font-size:2rem; font-weight:700; }
  .positive    { color:#059669; }
  .negative    { color:#dc2626; }
  .warning     { color:#d97706; }

  .ai-card     { background:#fffbeb; border:1px solid #fcd34d; border-radius:10px; padding:1.25rem; margin-bottom:1.5rem; }
  .ai-card h3  { margin:0 0 .75rem; font-size:1rem; }
  .ai-card pre { white-space:pre-wrap; font-family:inherit; font-size:.9rem; margin:0; }

  /* Mirrors original .card / table styles from index.tsx */
  .card        { background:#fff; border-radius:8px; padding:1.5rem; margin-bottom:1rem; box-shadow:0 1px 3px rgba(0,0,0,.1); }
  .card h3     { font-size:1.1rem; font-weight:600; margin:0 0 1rem; }
  table        { width:100%; border-collapse:collapse; }
  th,td        { padding:.65rem .75rem; text-align:right; border-bottom:1px solid #dcdfe3; font-size:.875rem; }
  th           { background:#f7f7f7; font-weight:600; color:#374151; }
  th:first-child, td:first-child { text-align:left; }
  .pos         { color:#059669; }
  .neg         { color:#dc2626; }

  .cat-list    { list-style:none; padding:0; display:flex; flex-direction:column; gap:.5rem; }
  .cat-list li { display:grid; grid-template-columns:120px 1fr 90px; align-items:center; gap:.75rem; font-size:.875rem; }
  .bar-track   { background:#f3f4f6; border-radius:4px; height:8px; overflow:hidden; }
  .bar         { background:#007aff; height:100%; border-radius:4px; }
  .cat-amt     { text-align:right; font-weight:500; }

  .actions     { display:flex; gap:1rem; margin-top:1.5rem; flex-wrap:wrap; }
  .btn         { padding:.65rem 1.25rem; background:#007aff; color:#fff; border-radius:8px; text-decoration:none; font-weight:500; font-size:.9rem; }
  .btn.outline { background:#fff; border:1px solid #d1d5db; color:#374151; cursor:pointer; }
</style>
