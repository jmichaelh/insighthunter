<script lang="ts">
  import { onMount }  from 'svelte';
  import { api }      from '@/lib/api';
  import Spinner      from '@/components/shared/Spinner.svelte';

  interface Insight {
    id:       string;
    type:     'warning' | 'opportunity' | 'info';
    priority: 'high' | 'medium' | 'low';
    title:    string;
    body:     string;
    cta?:     { label: string; href: string };
    createdAt: string;
  }

  let insights: Insight[] = [];
  let loading              = true;
  let error                = '';
  let expanded: string | null = null;

  onMount(async () => {
    const res = await api.get<Insight[]>('/insights?limit=5');
    if ('data' in res) insights = res.data;
    else error = res.error;
    loading = false;
  });

  const TYPE_CONFIG = {
    warning:     { icon: '⚠️', color: 'var(--color-warning)', bg: '#fdf6ec' },
    opportunity: { icon: '💡', color: 'var(--color-success)', bg: '#edfaf3' },
    info:        { icon: 'ℹ️', color: 'var(--color-info)',    bg: '#eef4fb' },
  };

  const PRIORITY_DOT = {
    high:   'var(--color-danger)',
    medium: 'var(--color-warning)',
    low:    'var(--color-sand-400)',
  };
</script>

<div class="insight-card">
  <div class="insight-card__header">
    <h3 class="panel-title">AI CFO Insights</h3>
    <a href="/dashboard/insights" class="insight-card__link">View all →</a>
  </div>

  {#if loading}
    <div class="insight-loading"><Spinner size="sm" /></div>
  {:else if error}
    <p class="insight-error">{error}</p>
  {:else if insights.length === 0}
    <div class="insight-empty">
      <span>🤖</span>
      <p>No insights yet. Add transactions to get AI-powered recommendations.</p>
    </div>
  {:else}
    <ul class="insight-list">
      {#each insights as insight (insight.id)}
        {@const cfg = TYPE_CONFIG[insight.type]}
        <li
          class="insight-item"
          style="--bg:{cfg.bg}; --border:{cfg.color}"
        >
          <!-- Header row -->
          <button
            class="insight-item__header"
            on:click={() => expanded = expanded === insight.id ? null : insight.id}
            aria-expanded={expanded === insight.id}
          >
            <span class="insight-item__icon" aria-hidden="true">{cfg.icon}</span>
            <span class="insight-item__title">{insight.title}</span>
            <span
              class="insight-item__dot"
              style="background:{PRIORITY_DOT[insight.priority]}"
              title="{insight.priority} priority"
            />
            <span class="insight-item__chevron" class:rotated={expanded === insight.id}>
              ›
            </span>
          </button>

          <!-- Expandable body -->
          {#if expanded === insight.id}
            <div class="insight-item__body">
              <p>{insight.body}</p>
              {#if insight.cta}
                <a href={insight.cta.href} class="btn btn--sm btn--primary" style="margin-top:10px">
                  {insight.cta.label} →
                </a>
              {/if}
            </div>
          {/if}
        </li>
      {/each}
    </ul>
  {/if}
</div>

<style>
  .insight-card {
    background:     #fff;
    border:         1px solid var(--color-border);
    border-radius:  var(--radius-lg);
    padding:        1.25rem;
    box-shadow:     var(--shadow-card);
    display:        flex;
    flex-direction: column;
    gap:            0.75rem;
  }

  .insight-card__header {
    display:         flex;
    justify-content: space-between;
    align-items:     center;
  }
  .insight-card__link {
    font-size:       0.8rem;
    color:           var(--color-text-muted);
    text-decoration: none;
  }
  .insight-card__link:hover { color: var(--color-primary-dark); }

  .insight-loading { display: flex; justify-content: center; padding: 1.5rem 0; }

  .insight-error { color: var(--color-danger); font-size: 0.875rem; }

  .insight-empty {
    display:        flex;
    flex-direction: column;
    align-items:    center;
    padding:        1.5rem 0;
    gap:            8px;
    color:          var(--color-text-muted);
    font-size:      0.875rem;
    text-align:     center;
    span { font-size: 2rem; }
  }

  .insight-list {
    list-style: none;
    display:    flex;
    flex-direction: column;
    gap:        6px;
  }

  .insight-item {
    border:        1px solid var(--border, var(--color-border));
    border-left:   3px solid var(--border, var(--color-border));
    border-radius: var(--radius-md);
    background:    var(--bg, #fff);
    overflow:      hidden;
  }

  .insight-item__header {
    display:     flex;
    align-items: center;
    gap:         8px;
    width:       100%;
    padding:     10px 12px;
    background:  none;
    border:      none;
    cursor:      pointer;
    text-align:  left;
  }
  .insight-item__header:hover { filter: brightness(0.97); }

  .insight-item__icon { font-size: 1rem; flex-shrink: 0; }

  .insight-item__title {
    flex:        1;
    font-size:   0.875rem;
    font-weight: 600;
    color:       var(--color-text);
    text-align:  left;
  }

  .insight-item__dot {
    width:         8px;
    height:        8px;
    border-radius: 50%;
    flex-shrink:   0;
  }

  .insight-item__chevron {
    font-size:   1.1rem;
    color:       var(--color-text-muted);
    transition:  transform 0.2s;
    line-height: 1;
  }
  .insight-item__chevron.rotated { transform: rotate(90deg); }

  .insight-item__body {
    padding:     0 12px 12px 12px;
    font-size:   0.875rem;
    color:       var(--color-text-muted);
    line-height: 1.6;
    display:     flex;
    flex-direction: column;
    align-items: flex-start;
  }
</style>
