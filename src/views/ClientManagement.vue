<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <h1>👥 Client Management</h1>
          <p class="subtitle">Manage your client relationships</p>
        </div>

        <div class="content-card card">
          <h3>🚧 Coming Soon</h3>
          <p>The Client Management feature is being built.</p>
          <p>This will include:</p>
          <ul>
            <li>Complete client contact information</li>
            <li>Project history per client</li>
            <li>Notes and tags</li>
            <li>Quick quote creation from client record</li>
            <li>Search and filter clients</li>
          </ul>
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

.page-header h1 {
  margin-bottom: 0.5rem;
}

.subtitle {
  color: var(--text-secondary);
  margin: 0;
}

.content-card {
  max-width: 800px;
  margin: 0 auto;
}

.content-card h3 {
  margin-bottom: 1rem;
}

.content-card ul {
  margin: 1.5rem 0;
  padding-left: 1.5rem;
}

.content-card li {
  margin-bottom: 0.5rem;
  color: var(--text-secondary);
}
</style>
