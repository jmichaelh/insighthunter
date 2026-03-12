<script lang="ts">
  import { onMount }   from 'svelte';
  import { api }       from '@/lib/api';
  import Spinner       from '@/components/shared/Spinner.svelte';
  import EmptyState    from '@/components/shared/EmptyState.astro';

  interface Activity {
    id:        string;
    label:     string;
    detail?:   string;
    type:      'transaction' | 'report' | 'insight' | 'formation' | 'login' | 'upload';
    timestamp: string;
  }

  const TYPE_ICONS: Record<Activity['type'], string> = {
    transaction: '💳',
    report:      '📊',
    insight:     '🤖',
    formation:   '🏛️',
    login:       '🔑',
    upload:      '📂',
  };

  let items:   Activity[] = [];
  let loading              = true;
  let error                = '';

  onMount(async () => {
    const res = await api.get<Activity[]>('/dashboard/activity?limit=10');
    if ('data' in res) {
      items = res.data;
    } else {
      error = res.error;
    }
    loading = false;
  });

  function timeAgo(iso: string): string {
    const diff = Date.now() - new Date(iso).getTime();
    const mins  = Math.floor(diff / 60_000);
    const hrs   = Math.floor(diff / 3_600_000);
    const days  = Math.floor(diff / 86_400_000);
    if (mins < 1)   return 'Just now';
    if (mins < 60)  return `${mins}m ago`;
    if (hrs  < 24)  return `${hrs}h ago`;
    if (days < 7)   return `${days}d ago`;
    return new Date(iso).toLocaleDateString();
  }
</script>

<div class="activity-feed">
  <div class="feed-header">
    <h3 class="panel-title">Recent Activity</h3>
    <a href="/dashboard/reports" class="feed-header__link">View all →</a>
  </div>

  {#if loading}
    <div class="feed-loading"><Spinner size="sm" /></div>
  {:else if error}
    <p class="feed-error">{error}</p>
  {:else if items.length === 0}
    <div class="feed-empty">
      <span class="feed-empty__icon">📭</span>
      <p>No recent activity yet.</p>
    </div>
  {:else}
    <ul class="feed-list">
      {#each items as item (item.id)}
        <li class="feed-item">
          <span class="feed-item__icon feed-item__icon--{item.type}" aria-hidden="true">
            {TYPE_ICONS[item.type]}
          </span>
          <div class="feed-item__body">
            <p class="feed-item__label">{item.label}</p>
            {#if item.detail}
              <p class="feed-item__detail">{item.detail}</p>
            {/if}
          </div>
          <time class="feed-item__time" datetime={item.timestamp}>
            {timeAgo(item.timestamp)}
          </time>
        </li>
      {/each}
    </ul>
  {/if}
</div>

<style>
  .activity-feed {
    background:    #fff;
    border:        1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding:       1.25rem;
    box-shadow:    var(--shadow-card);
    display:       flex;
    flex-direction: column;
    gap:           0.75rem;
  }

  .feed-header {
    display:         flex;
    justify-content: space-between;
    align-items:     center;
  }
  .feed-header__link {
    font-size:       0.8rem;
    color:           var(--color-text-muted);
    text-decoration: none;
  }
  .feed-header__link:hover { color: var(--color-primary-dark); }

  .feed-loading {
    display:         flex;
    justify-content: center;
    padding:         1.5rem 0;
  }

  .feed-error {
    font-size: 0.875rem;
    color:     var(--color-danger);
    padding:   0.5rem 0;
  }

  .feed-empty {
    display:        flex;
    flex-direction: column;
    align-items:    center;
    padding:        2rem 0;
    gap:            8px;
    color:          var(--color-text-muted);
    font-size:      0.875rem;
  }
  .feed-empty__icon { font-size: 2rem; }

  .feed-list {
    list-style: none;
    display:    flex;
    flex-direction: column;
    gap:        2px;
  }

  .feed-item {
    display:     flex;
    align-items: flex-start;
    gap:         10px;
    padding:     9px 6px;
    border-radius: var(--radius-md);
    transition:  background 0.12s;
  }
  .feed-item:hover { background: var(--color-sand-50); }

  .feed-item__icon {
    font-size:   1.1rem;
    width:       32px;
    height:      32px;
    border-radius: 50%;
    background:  var(--color-sand-100);
    display:     flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    line-height: 1;
  }

  .feed-item__body { flex: 1; min-width: 0; }

  .feed-item__label {
    font-size:     0.875rem;
    font-weight:   500;
    color:         var(--color-text);
    white-space:   nowrap;
    overflow:      hidden;
    text-overflow: ellipsis;
  }

  .feed-item__detail {
    font-size: 0.775rem;
    color:     var(--color-text-muted);
    margin-top: 1px;
  }

  .feed-item__time {
    font-size:   0.75rem;
    color:       var(--color-text-muted);
    white-space: nowrap;
    flex-shrink: 0;
    margin-top:  2px;
  }
</style>
