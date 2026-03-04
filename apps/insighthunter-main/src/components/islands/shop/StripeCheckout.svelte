<!-- apps/insighthunter-main/src/components/islands/shop/StripeCheckout.svelte -->
<script lang="ts">
  export let plan: 'standard' | 'pro';
  export let label: string = `Upgrade to ${plan}`;

  let loading = false;
  let error = '';

  async function startCheckout() {
    loading = true;
    error = '';
    try {
      const token = localStorage.getItem('ih_token');
      if (!token) { window.location.href = '/auth/login'; return; }

      const res = await fetch('/api/billing/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ plan }),
      });
      const data = await res.json();
      if (data.url) {
        window.location.href = data.url; // redirect to Stripe Checkout
      } else {
        error = data.error ?? 'Something went wrong';
      }
    } catch (e) {
      error = 'Network error — please try again';
    } finally {
      loading = false;
    }
  }
</script>

<button on:click={startCheckout} disabled={loading} class="btn-upgrade btn-{plan}">
  {loading ? 'Redirecting...' : label}
</button>

{#if error}
  <p class="error">{error}</p>
{/if}

