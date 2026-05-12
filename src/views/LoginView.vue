<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase.js'

const router = useRouter()
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function handleLogin() {
  if (email.value.trim() === '' || password.value.trim() === '') {
    error.value = 'Por favor, completa ambos campos.'
    return
  }

  loading.value = true
  error.value = ''

  const { data, error: err } = await supabase.auth.signInWithPassword({
    email: email.value.trim(),
    password: password.value
  })

  loading.value = false

  if (err) {
    error.value = 'Error al iniciar sesion. Revisa tus credenciales.'
    return
  }

  // Guardamos la contrasena en sessionStorage para derivar la clave de cifrado
  // al momento de guardar o leer del historial durante esta sesion.
  sessionStorage.setItem('pg_master_key', password.value)
  
  router.push('/')
}
</script>

<template>
  <main class="page">
    <div class="panel login-panel">
      <div class="brand">
        <div class="badge" aria-hidden="true">PG</div>
        <h1 class="title">Iniciar Sesion</h1>
      </div>
      
      <p class="subtitle">Generador de contrasenas</p>

      <form @submit.prevent="handleLogin" class="controls">
        <div class="row">
          <label class="label" for="email">Correo Electronico</label>
          <input
            id="email"
            class="text"
            type="email"
            v-model="email"
            placeholder="Introduce tu correo"
            autocomplete="email"
            required
          />
        </div>

        <div class="row">
          <label class="label" for="password">Contrasena</label>
          <input
            id="password"
            class="text"
            type="password"
            v-model="password"
            placeholder="Introduce tu contrasena"
            autocomplete="current-password"
            required
          />
        </div>

        <p v-if="error" class="error" role="status">{{ error }}</p>

        <button class="btn btn-block" type="submit" :disabled="loading">
          {{ loading ? 'Ingresando...' : 'Ingresar' }}
        </button>
      </form>
    </div>
  </main>
</template>

<style scoped>
.page {
  min-height: 100vh;
  display: grid;
  place-content: center;
  gap: 16px;
  padding: 28px 18px;
}

.login-panel {
  width: min(400px, calc(100vw - 32px));
  margin: 0 auto;
}

.brand {
  display: flex;
  gap: 12px;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
}

.badge {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, rgba(142, 189, 255, 0.9), rgba(199, 142, 255, 0.8));
  color: rgba(0, 0, 0, 0.88);
  font-weight: 800;
  letter-spacing: 0.6px;
}

.title {
  margin: 0;
  font-size: 24px;
  line-height: 1.2;
}

.subtitle {
  margin: 0 0 24px;
  color: var(--fg-muted);
  text-align: center;
}

.panel {
  border: 1px solid var(--border);
  border-radius: 18px;
  background: var(--surface);
  box-shadow: 0 16px 60px rgba(0, 0, 0, 0.35);
  padding: 24px;
}

.controls {
  display: grid;
  gap: 16px;
}

.row {
  display: grid;
  gap: 8px;
}

.label {
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--fg-muted);
}

.text {
  width: 100%;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border-strong);
  background: var(--surface-3);
  color: var(--fg);
}

.btn {
  padding: 12px;
  border-radius: 12px;
  border: 1px solid var(--border-strong);
  background: var(--btn);
  cursor: pointer;
  transition: transform 80ms ease, background 120ms ease;
  font-weight: 600;
  color: var(--fg);
}

.btn:hover:not(:disabled) {
  background: var(--btn-hover);
}

.btn:active:not(:disabled) {
  transform: translateY(1px);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-block {
  width: 100%;
  margin-top: 8px;
}

.error {
  margin: 0;
  color: rgba(255, 180, 180, 0.95);
  font-size: 13px;
  text-align: center;
}
</style>