<script lang="ts">
  import { showToast } from '@/components/shared/Toast.svelte';

  interface QuickAction {
    label:       string;
    href?:       string;
    icon:        string;
    description: string;
    action?:     () => void | Promise<void>;
    tier?:       string;
  }

  const ACTIONS: QuickAction[] = [
    {
      label:       'Upload Statement',
      href:        '/dashboard/bookkeeping',
      icon:        '📂',
      description: 'Import a bank CSV',
    },
    {
      label:       'Run P&L Report',
      href:        '/dashboard/reports',
      icon:        '📊',
      description: 'Generate profit & loss',
    },
    {
      label:       'Ask AI CFO',
      href:        '/dashboard/insights',
      icon:        '🤖',
      description: 'Chat with your CFO AI',
    },
    {
      label:       'New Formation',
      href:        '/dashboard/bizforma',
      icon:        '🏛️',
      description: 'Start entity formation',
    },
    {
      label:       'View Forecast',
      href:        '/dashboard/forecast',
      icon:        '📈',
      description: '90-day cash projection',
    },
    {
      label:       'Export PDF',
      icon:        '⬇',
      description: 'Download latest report',
      action:      async () => {
        showToast('Generating PDF…', 'info', 1500);
        const res = await fetch('/api/reports/pl/pdf', { credentials: 'include' });
        if (!res.ok) { showToast('Export failed.', 'error'); return; }
        const blob = await res.blob();
        const url  = URL.createObjectURL(blob);
        const a    = document.createElement('a');
        a.href     = url;
        a.download = 'insighthunter_report.pdf';
        a.click();
        URL.revokeObjectURL(url);
        showToast('Report downloaded.', 'success');
      },
    },
  ];

  async function handleClick(action: QuickAction, e: MouseEvent) {
    if (action.action) {
      e.preventDefault();
      await action.action();
    }
  }
</script>

<div class="quick-actions">
  <h3 class="panel-title">Quick Actions</h3>
  <div class="quick-actions__grid">
    {#each ACTIONS as action}
      <svelte:element
        this={action.href ? 'a' : 'button'}
        href={action.href}
        class="qa-btn"
        type={action.href ? undefined : 'button'}
        on:click={(e) => handleClick(action, e)}
        title={action.description}
      >
        <span class="qa-btn__icon" aria-hidden="true">{action.icon}</span>
        <span class="qa-btn__label">{action.label}</span>
        <span class="qa-btn__desc">{action.description}</span>
      </svelte:element>
    {/each}
  </div>
</div>

<style>
  .quick-actions {
    background:    #fff;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding:       1.25rem;
    box-shadow:    var(--shadow-card);
    display:       flex;
    flex-direction: column;
    gap:           0.875rem;
  }

  .quick-actions__grid {
    display:               grid;
    grid-template-columns: repeat(3, 1fr);
    gap:                   8px;
  }

  @media (max-width: 640px) {
    .quick-actions__grid { grid-template-columns: repeat(2, 1fr); }
  }

  .qa-btn {
    display:        flex;
    flex-direction: column;
    align-items:    flex-start;
    gap:            4px;
    padding:        12px;
    background:     var(--color-sand-50);
    border:         1px solid var(--color-border);
    border-radius:  var(--radius-md);
    cursor:         pointer;
    text-decoration: none;
    color:          inherit;
    transition:     background 0.12s, box-shadow 0.12s, transform 0.12s;
    text-align:     left;
  }
  .qa-btn:hover {
    background:  var(--color-sand-100);
    box-shadow:  var(--shadow-card);
    transform:   translateY(-1px);
    text-decoration: none;
  }
  .qa-btn:active { transform: translateY(0); }

  .qa-btn__icon  { font-size: 1.3rem; line-height: 1; }
  .qa-btn__label { font-size: 0.8rem; font-weight: 600; color: var(--color-text); }
  .qa-btn__desc  { font-size: 0.72rem; color: var(--color-text-muted); line-height: 1.3; }
</style>
