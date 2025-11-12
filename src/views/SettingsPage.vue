<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <h1>⚙️ Settings</h1>
        </div>

        <div class="content-card card">
          <h3>🚧 Coming Soon</h3>
          <p>Settings pages are being built.</p>
          <router-link to="/dashboard" class="btn btn-primary">Back to Dashboard</router-link>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import NavigationBar from '@/components/NavigationBar.vue'
</script>

<style scoped>
.page-layout {
  min-height: 100vh;
  background-color: var(--bg-secondary);
}

.page-main {
  padding: 2rem 0 4rem;
}

.page-header {
  margin-bottom: 2rem;
}

.content-card {
  max-width: 800px;
  margin: 0 auto;
}
</style>
