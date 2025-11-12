import { createClient } from '@supabase/supabase-js'

// Prefer Vite env at build-time, but fall back to runtime window.__ENV for static hosting
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || (typeof window !== 'undefined' && window.__ENV?.VITE_SUPABASE_URL)
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || (typeof window !== 'undefined' && window.__ENV?.VITE_SUPABASE_ANON_KEY)

// Provide a safe fallback when env vars are missing so the app can still render
function createNotConfiguredClient() {
  const notConfigured = async () => ({ data: null, error: new Error('Supabase is not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in your .env file.') })
  console.warn('[Greenline] Supabase environment variables are missing. The app will render but backend calls will fail until configured.')
  return {
    auth: {
      getSession: async () => ({ data: { session: null }, error: new Error('Supabase not configured') }),
      signUp: notConfigured,
      signInWithPassword: notConfigured,
      signInWithOAuth: notConfigured,
      signOut: async () => ({ error: new Error('Supabase not configured') }),
      resetPasswordForEmail: notConfigured,
      updateUser: notConfigured,
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } })
    },
    from: () => ({
      select: notConfigured,
      insert: notConfigured,
      update: notConfigured,
      delete: notConfigured,
      eq: () => ({ select: notConfigured })
    })
  }
}

export const supabase = (supabaseUrl && supabaseAnonKey)
  ? createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true
      }
    })
  : createNotConfiguredClient()
