<script>
  import "../../styles/globals.scss";
  import "../../styles/dashboard.scss";
  import Sidebar from "../../components/dashboard/Sidebar.svelte";
  import TopBar from "../../components/dashboard/TopBar.svelte";

  export let data;
</script>

<div class="dash-layout">
  <Sidebar currentPath={data.currentPath} sessionToken={data.sessionToken} />

  <div class="dash-main">
    <TopBar sessionToken={data.sessionToken} />

    <main class="dash-content">
      <slot />
    </main>
  </div>
</div>

<div
  id="toast-root"
  style="position:fixed;bottom:1.5rem;right:1.5rem;z-index:9999;display:flex;flex-direction:column;gap:0.5rem;pointer-events:none;"
></div>
