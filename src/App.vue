<template>
  <div id="app" class="app-container">
    <router-view />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onMounted(() => {
  // Initialize auth session on app load
  authStore.initialize()
})
</script>

<style>
.app-container {
  min-height: 100vh;
  background: var(--bg-primary);
}
</style>
