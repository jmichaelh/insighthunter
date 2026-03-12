<script>
  import { onMount } from 'svelte';

  onMount(() => {
    const header = document.getElementById('header');
    window.addEventListener('scroll', () => {
      header?.classList.toggle('scrolled', window.scrollY > 10);
    });
  });
</script>

<header class="header" id="header">
  <a href="/" class="brand">Insight<span>Hunter</span></a>
  <nav class="nav">
    <a href="/features">Features</a>
    <a href="/pricing">Pricing</a>
    <a href="/marketing/about">About</a>
    <a href="/auth/login" class="text-primary">Log In</a>
    <a href="#demo" class="btn-secondary">Book a Demo</a>
    <a href="/auth/signup" class="btn-primary">Start Free →</a>
  </nav>
</header>

<style>
  .header {
    background-color: var(--bg-white);
    border-bottom: 1px solid var(--border-color);
  }
  .brand {
    color: var(--text-primary);
  }
  .brand span {
    color: var(--primary-color);
  }
  .nav a {
    color: var(--text-secondary);
  }
  .nav a:hover {
    color: var(--primary-color);
  }
  .btn-primary {
    background-color: var(--primary-color);
    color: var(--bg-white);
    border-radius: var(--border-radius-md);
    padding: var(--spacing-sm) var(--spacing-md);
  }
  .btn-secondary {
    background-color: var(--secondary-color);
    color: var(--bg-white);
    border-radius: var(--border-radius-md);
    padding: var(--spacing-sm) var(--spacing-md);
  }
</style>
