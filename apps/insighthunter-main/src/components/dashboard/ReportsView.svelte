<script lang="ts">
  import { onMount }   from 'svelte';
  import { api }       from '@/lib/api';
  import Spinner       from '@/components/shared/Spinner.svelte';

  type ReportType = 'pl' | 'cash_flow' | 'balance_sheet';

  interface ReportLine { label: string; amount: number; indent?: boolean; bold?: boolean }
  interface Report     { title: string; period: string; lines: ReportLine[]; generatedAt: string }

  let activeReport: ReportType = 'pl';
  let report:       Report | null = null;
  let loading                     = false;
  let error                       = '';

  const REPORT_LABELS: Record<ReportType, string> = {
    pl:            'Profit & Loss',
    cash_flow:     'Cash Flow Statement',
    balance_sheet: 'Balance Sheet',
  };

  async function loadReport(type: ReportType) {
    activeReport = type;
    loading      = true;
    error        = '';
    const res    = await api.get<Report>(`/reports/${type}`);
    if ('data' in res) {
      report = res.data;
    } else {
      error  = res.error;
    }
    loading = false;
  }

  onMount(() => loadReport('pl'));

  function fmt(n: number): string {
    const abs = Math.abs(n);
    const str = new Intl.NumberFormat('en-US', {
      style: 'currency', currency: 'USD', maximumFractionDigits: 0,
    }).format(abs);
    return n < 0 ? `(${str})` : str;
  }

  async function exportPDF() {
    const res = await fetch(`/api/reports/${activeReport}/pdf`, {
      credentials: 'include',
    });
    if (!res.ok) return;
    const blob = await res.blob();
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href     = url;
    a.download = `${activeReport}_report.pdf`;
    a.click();
    URL.revokeObjectURL(url);
  }
</script>

<div class="reports-view">
  <!-- Tab bar -->
  <div class="reports-tabs">
    {#each Object.entries(REPORT_LABELS) as [type, label]}
      <button
        class="reports-tab"
        class:active={activeReport === type}
        on:click={() => loadReport(type as ReportType)}
      >
        {label}
      </button>
    {/each}
  </div>

  <!-- Toolbar -->
  <div class="reports-toolbar">
    {#if report}
      <span class="reports-period">{report.period}</span>
      <button class="btn btn--sm btn--outline" on:click={exportPDF}>
        ⬇ Export PDF
      </button>
    {/if}
  </div>

  <!-- Content -->
  {#if loading}
    <div class="reports-loading"><Spinner /></div>
  {:else if error}
    <div class="reports-error">{error}</div>
  {:else if report}
    <div class="report-table">
      <div class="report-table__header">
        <h2>{report.title}</h2>
        <span>Generated {new Date(report.generatedAt).toLocaleDateString()}</span>
      </div>
      <table>
        <tbody>
          {#each report.lines as line}
            <tr class:bold={line.bold} class:indent={line.indent}>
              <td class="report-label">{line.label}</td>
              <td class="report-amount" class:negative={line.amount < 0}>
                {fmt(line.amount)}
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {:else}
    <div class="empty">Select a report type to get started.</div>
  {/if}
</div>

<style>
  .reports-view { display: flex; flex-direction: column; gap: 1.25rem; }

  .reports-tabs {
    display: flex;
    gap: 4px;
    border-bottom: 2px solid var(--color-border);
    padding-bottom: 0;
  }
  .reports-tab {
    padding: 10px 20px;
    background: none;
    border: none;
    border-bottom: 2px solid transparent;
    cursor: pointer;
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--color-text-muted);
    margin-bottom: -2px;
    transition: all 0.15s;
    &:hover { color: var(--color-text); }
    &.active {
      color: var(--color-primary-dark);
      border-bottom-color: var(--color-primary);
      font-weight: 600;
    }
  }

  .reports-toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .reports-period { font-size: 0.875rem; color: var(--color-text-muted); }

  .reports-loading { display: flex; justify-content: center; padding: 3rem; }
  .reports-error   { color: var(--color-danger); padding: 1rem; }

  .report-table {
    background: #fff;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    overflow: hidden;
    box-shadow: var(--shadow-card);
  }
  .report-table__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.25rem 1.5rem;
    border-bottom: 1px solid var(--color-border);
    h2    { font-size: 1.1rem; font-weight: 700; }
    span  { font-size: 0.8rem; color: var(--color-text-muted); }
  }

  table { width: 100%; border-collapse: collapse; }

  tr {
    border-bottom: 1px solid var(--color-border);
    &:last-child { border-bottom: none; }
    &.bold td { font-weight: 700; background: var(--color-sand-50); }
    &.indent .report-label { padding-left: 2.5rem; }
  }

  .report-label  { padding: 10px 1.5rem; font-size: 0.875rem; }
  .report-amount { padding: 10px 1.5rem; text-align: right; font-size: 0.875rem; font-variant-numeric: tabular-nums; }
  .negative { color: var(--color-danger); }

  .empty {
    text-align: center;
    color: var(--color-text-muted);
    padding: 3rem;
    font-size: 0.875rem;
  }
</style>
