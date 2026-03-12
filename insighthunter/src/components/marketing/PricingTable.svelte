<script lang="ts">
  import type { PricingTier } from '$lib/types/apps';

  export let tiers: PricingTier[];
</script>

<section class="pricing-table">
  <div class="pricing-container">
    <div class="pricing-header">
      <h2>Find the Perfect Plan</h2>
      <p>Start for free, then upgrade as you grow.</p>
    </div>
    <div class="pricing-grid">
      {#each tiers as tier}
        <div class="pricing-card" class:highlighted={tier.highlighted}>
          <div class="card-header">
            <h3 class="tier-name">{tier.name}</h3>
            <p class="tier-price">{tier.priceLabel}</p>
            <p class="tier-description">{tier.description}</p>
          </div>
          <div class="card-features">
            <ul>
              {#each tier.features as feature}
                <li>{feature}</li>
              {/each}
            </ul>
          </div>
          <div class="card-cta">
            <a href={tier.ctaHref} class="btn" class:btn-primary={tier.highlighted} class:btn-secondary={!tier.highlighted}>
              {tier.cta}
            </a>
          </div>
        </div>
      {/each}
    </div>
  </div>
</section>

<style>
  .pricing-table {
    padding: var(--spacing-xl) 0;
  }

  .pricing-container {
    max-width: var(--max-width);
    margin: 0 auto;
    padding: 0 var(--spacing-md);
  }

  .pricing-header {
    text-align: center;
    margin-bottom: var(--spacing-xl);
  }

  .pricing-header h2 {
    font-size: 2.5rem;
    font-weight: var(--font-weight-bold);
    color: var(--text-primary);
    margin-bottom: var(--spacing-sm);
  }

  .pricing-header p {
    font-size: 1.125rem;
    color: var(--text-secondary);
  }

  .pricing-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: var(--spacing-lg);
    align-items: stretch;
  }

  .pricing-card {
    background-color: var(--bg-elevated);
    border: 1px solid var(--border-subtle);
    border-radius: var(--border-radius-lg);
    padding: var(--spacing-lg);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }

  .pricing-card.highlighted {
    border-color: var(--primary-color);
    box-shadow: var(--shadow-strong-glow);
    transform: scale(1.05);
  }

  .card-header {
    text-align: center;
    margin-bottom: var(--spacing-lg);
  }

  .tier-name {
    font-size: 1.75rem;
    font-weight: var(--font-weight-bold);
    color: var(--text-primary);
    margin-bottom: var(--spacing-sm);
  }

  .tier-price {
    font-size: 1.25rem;
    font-weight: var(--font-weight-bold);
    color: var(--primary-color);
    margin-bottom: var(--spacing-sm);
  }

  .tier-description {
    color: var(--text-secondary);
  }

  .card-features ul {
    list-style: none;
    padding: 0;
    margin: 0 0 var(--spacing-lg) 0;
  }

  .card-features li {
    margin-bottom: var(--spacing-sm);
    display: flex;
    align-items: center;
  }

 .card-features li::before {
    content: '✓';
    color: var(--success-color);
    font-weight: bold;
    margin-right: var(--spacing-sm);
  }

  .card-cta {
    text-align: center;
  }

  .btn {
    display: inline-block;
    border-radius: var(--border-radius-md);
    padding: var(--spacing-md) var(--spacing-xl);
    text-decoration: none;
    font-weight: var(--font-weight-bold);
    width: 100%;
  }

  .btn-primary {
    background-color: var(--primary-color);
    color: var(--bg-dark);
    box-shadow: var(--shadow-soft-glow);
  }

  .btn-secondary {
    background-color: transparent;
    color: var(--primary-color);
    border: 1px solid var(--primary-color);
  }

  @media (max-width: 768px) {
    .pricing-grid {
      grid-template-columns: 1fr;
    }
    .pricing-card.highlighted {
        transform: scale(1);
    }
  }
</style>
