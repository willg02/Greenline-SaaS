<template>
  <div class="auth-page">
    <div class="auth-container">
      <div class="auth-card card">
        <div class="auth-header">
          <h1>🌿 Greenline</h1>
          <p>Create your account</p>
        </div>

        <div v-if="error" class="alert alert-error">
          {{ error }}
        </div>

        <div v-if="success" class="alert alert-success">
          {{ success }}
        </div>

        <form @submit.prevent="handleSignUp" class="auth-form">
          <div class="input-group">
            <label for="fullName" class="input-label">Full Name</label>
            <input
              id="fullName"
              v-model="fullName"
              type="text"
              class="input-field"
              placeholder="John Doe"
              required
              autocomplete="name"
            />
          </div>

          <div class="input-group">
            <label for="email" class="input-label">Email</label>
            <input
              id="email"
              v-model="email"
              type="email"
              class="input-field"
              placeholder="you@example.com"
              required
              autocomplete="email"
            />
          </div>

          <div class="input-group">
            <label for="organizationName" class="input-label">Organization Name</label>
            <input
              id="organizationName"
              v-model="organizationName"
              type="text"
              class="input-field"
              placeholder="Your Landscaping Business"
              required
            />
            <small class="input-hint">You can add team members later</small>
          </div>

          <div class="input-group">
            <label for="password" class="input-label">Password</label>
            <input
              id="password"
              v-model="password"
              type="password"
              class="input-field"
              placeholder="••••••••"
              required
              autocomplete="new-password"
              minlength="8"
            />
            <small class="input-hint">Minimum 8 characters</small>
          </div>

          <div class="input-group">
            <label for="confirmPassword" class="input-label">Confirm Password</label>
            <input
              id="confirmPassword"
              v-model="confirmPassword"
              type="password"
              class="input-field"
              placeholder="••••••••"
              required
              autocomplete="new-password"
            />
          </div>

          <button type="submit" class="btn btn-primary btn-lg" :disabled="loading" style="width: 100%;">
            {{ loading ? 'Creating account...' : 'Create Account' }}
          </button>
        </form>

        <div class="divider">
          <span>or</span>
        </div>

        <button @click="handleGoogleSignIn" class="btn btn-secondary btn-lg" style="width: 100%;">
          <svg width="18" height="18" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
            <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
            <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
            <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
            <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
            <path fill="none" d="M0 0h48v48H0z"/>
          </svg>
          Continue with Google
        </button>

        <div class="auth-switch">
          Already have an account?
          <router-link to="/login">Sign in</router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const fullName = ref('')
const email = ref('')
const organizationName = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref(null)
const success = ref(null)

async function handleSignUp() {
  try {
    loading.value = true
    error.value = null
    success.value = null

    // Validate passwords match
    if (password.value !== confirmPassword.value) {
      error.value = 'Passwords do not match'
      return
    }

    const { error: signUpError } = await authStore.signUp(
      email.value,
      password.value,
      organizationName.value,
      fullName.value
    )

    if (signUpError) {
      error.value = signUpError.message || 'Failed to create account'
      return
    }

    success.value = 'Account created! Please check your email to confirm your account.'
    
    // Redirect to login after a delay
    setTimeout(() => {
      router.push('/login')
    }, 3000)
  } catch (err) {
    error.value = 'An unexpected error occurred'
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function handleGoogleSignIn() {
  try {
    error.value = null
    const { error: signInError } = await authStore.signInWithGoogle()

    if (signInError) {
      error.value = signInError.message || 'Failed to sign in with Google'
    }
  } catch (err) {
    error.value = 'An unexpected error occurred'
    console.error(err)
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: var(--spacing-lg);
}

.auth-container {
  width: 100%;
  max-width: 420px;
}

.auth-card {
  background-color: var(--color-white);
}

.auth-header {
  text-align: center;
  margin-bottom: var(--spacing-xl);
}

.auth-header h1 {
  font-size: 2rem;
  margin-bottom: var(--spacing-sm);
  color: var(--color-primary);
}

.auth-header p {
  color: var(--text-secondary);
  margin-bottom: 0;
}

.auth-form {
  margin-bottom: var(--spacing-lg);
}

.input-hint {
  display: block;
  margin-top: var(--spacing-xs);
  font-size: 0.875rem;
  color: var(--text-tertiary);
}

.divider {
  position: relative;
  text-align: center;
  margin: var(--spacing-xl) 0;
}

.divider::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 1px;
  background-color: var(--border-color);
}

.divider span {
  position: relative;
  display: inline-block;
  padding: 0 var(--spacing-md);
  background-color: var(--color-white);
  color: var(--text-tertiary);
  font-size: 0.875rem;
}

.auth-switch {
  text-align: center;
  margin-top: var(--spacing-lg);
  color: var(--text-secondary);
}

.auth-switch a {
  color: var(--color-primary);
  font-weight: 500;
  text-decoration: none;
}

.auth-switch a:hover {
  text-decoration: underline;
}
</style>
