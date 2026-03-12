<script lang="ts">
  import { toasts } from '$lib/stores/toast';
</script>

<div class="fixed bottom-6 right-6 z-50 flex flex-col gap-2">
  {#each $toasts as toast (toast.id)}
    <div class="flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg text-sm font-medium min-w-64 max-w-sm
                animate-in slide-in-from-right"
         class:bg-green-600={toast.type === 'success'}
         class:bg-red-600={toast.type === 'error'}
         class:bg-sand-800={toast.type === 'info'}>
      <span>{toast.type === 'success' ? '✓' : toast.type === 'error' ? '✕' : 'ℹ'}</span>
      <span class="text-white flex-1">{toast.message}</span>
      <button on:click={() => toasts.dismiss(toast.id)} class="text-white/70 hover:text-white ml-2">✕</button>
    </div>
  {/each}
</div>
