<template>
  <div class="page-layout">
    <NavigationBar />
    <main class="page-main">
      <div class="container">
        <div class="page-header">
          <h1>⚙️ Settings</h1>
          <p class="page-description">Manage your account and organization settings</p>
        </div>

        <div class="settings-grid">
          <router-link to="/settings/organization" class="settings-card card">
            <div class="settings-icon">🏢</div>
            <h3>Organization Settings</h3>
            <p>Manage team members, roles, and permissions</p>
          </router-link>

          <router-link to="/settings/billing" class="settings-card card">
            <div class="settings-icon">💳</div>
            <h3>Billing</h3>
            <p>Manage subscription and payment methods</p>
          </router-link>

          <div class="settings-card card disabled">
            <div class="settings-icon">👤</div>
            <h3>Profile Settings</h3>
            <p>Coming soon - Update your personal information</p>
          </div>

          <div class="settings-card card disabled">
            <div class="settings-icon">🔔</div>
            <h3>Notifications</h3>
            <p>Coming soon - Configure notification preferences</p>
          </div>
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

.page-description {
  color: var(--text-secondary);
  margin-top: 0.5rem;
}

.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  max-width: 1200px;
}

.settings-card {
  padding: 2rem;
  text-decoration: none;
  color: inherit;
  transition: all var(--transition-fast);
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  border: 2px solid transparent;
}

.settings-card:not(.disabled) {
  cursor: pointer;
}

.settings-card:not(.disabled):hover {
  border-color: var(--color-primary);
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.settings-card.disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.settings-icon {
  font-size: 2.5rem;
  margin-bottom: 1rem;
}

.settings-card h3 {
  margin-bottom: 0.5rem;
  color: var(--text-primary);
}

.settings-card p {
  color: var(--text-secondary);
  font-size: 0.9rem;
  line-height: 1.5;
}
</style>
