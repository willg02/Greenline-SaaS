<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <h1>Quote Details</h1>
        </div>

        <div class="content-card card">
          <p>Quote details page - Coming soon</p>
          <router-link to="/quotes" class="btn btn-secondary">Back to Quotes</router-link>
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
