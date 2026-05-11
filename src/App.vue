<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import {
  buildCharset,
  estimateStrengthBits,
  generatePassword,
} from './lib/password.js'

const year = new Date().getFullYear()

const length = ref(20)
const lower = ref(true)
const upper = ref(true)
const numbers = ref(true)
const symbols = ref(false)

const password = ref('')
const copyState = ref('idle')

const charset = computed(() =>
  buildCharset({
    lower: lower.value,
    upper: upper.value,
    numbers: numbers.value,
    symbols: symbols.value,
  })
)

const strengthBits = computed(() =>
  estimateStrengthBits({ length: length.value, charsetSize: charset.value.length })
)

const strengthLabel = computed(() => {
  const b = strengthBits.value
  if (b >= 80) return 'Muy fuerte'
  if (b >= 60) return 'Fuerte'
  if (b >= 40) return 'Media'
  return 'Debil'
})

const strengthTone = computed(() => {
  const b = strengthBits.value
  if (b >= 80) return 'good'
  if (b >= 60) return 'ok'
  if (b >= 40) return 'warn'
  return 'bad'
})

const canGenerate = computed(() => charset.value.length > 0)

function regenerate() {
  if (!canGenerate.value) {
    password.value = ''
    return
  }

  try {
    password.value = generatePassword({
      length: length.value,
      charset: charset.value,
    })
  } catch {
    password.value = ''
  }
}

async function copyToClipboard() {
  if (!password.value) return
  try {
    await navigator.clipboard.writeText(password.value)
    copyState.value = 'copied'
  } catch {
    // Fallback for older browsers or denied permission
    const el = document.createElement('textarea')
    el.value = password.value
    el.setAttribute('readonly', 'true')
    el.style.position = 'fixed'
    el.style.top = '-9999px'
    document.body.appendChild(el)
    el.select()
    const ok = document.execCommand('copy')
    document.body.removeChild(el)
    copyState.value = ok ? 'copied' : 'error'
  }

  window.clearTimeout(copyToClipboard._t)
  copyToClipboard._t = window.setTimeout(() => {
    copyState.value = 'idle'
  }, 1200)
}

watch([length, lower, upper, numbers, symbols], () => {
  // Keep the output fresh as options change.
  regenerate()
})

onMounted(() => {
  regenerate()
})
</script>

<template>
  <main class="page">
    <header class="header">
      <div class="brand">
        <div class="badge" aria-hidden="true">PG</div>
        <div class="brandText">
          <h1 class="title">Password Generator</h1>
          <p class="subtitle">Genera contrasenas aleatorias seguras</p>
        </div>
      </div>
    </header>

    <section class="panel" aria-label="Generador de contrasenas">
      <div class="output">
        <label class="label" for="password">Contrasena generada</label>
        <div class="outputRow">
          <input
            id="password"
            class="outputInput"
            :value="password"
            readonly
            autocomplete="off"
            spellcheck="false"
          />
          <button class="btn" type="button" @click="regenerate" :disabled="!canGenerate">
            Generar
          </button>
          <button
            class="btn btnGhost"
            type="button"
            @click="copyToClipboard"
            :disabled="!password"
            :aria-label="copyState === 'copied' ? 'Copiado' : 'Copiar'"
          >
            <span v-if="copyState === 'copied'">Copiado</span>
            <span v-else-if="copyState === 'error'">Error</span>
            <span v-else>Copiar</span>
          </button>
        </div>
        <div class="meta">
          <span class="chip" :data-tone="strengthTone">
            Fuerza: {{ strengthLabel }}
            <span class="chipHint">({{ Math.round(strengthBits) }} bits)</span>
          </span>
          <span class="chip">Set: {{ charset.length }} chars</span>
        </div>
      </div>

      <div class="divider" role="separator" aria-orientation="horizontal" />

      <form class="controls" @submit.prevent>
        <div class="row">
          <div class="field">
            <label class="label" for="length">Longitud</label>
            <div class="rangeRow">
              <input
                id="length"
                class="range"
                type="range"
                min="4"
                max="128"
                step="1"
                v-model.number="length"
              />
              <input
                class="number"
                type="number"
                min="4"
                max="128"
                step="1"
                v-model.number="length"
                aria-label="Longitud exacta"
              />
            </div>
          </div>
        </div>

        <div class="row switches">
          <label class="switch">
            <input type="checkbox" v-model="lower" />
            <span>Minusculas</span>
          </label>
          <label class="switch">
            <input type="checkbox" v-model="upper" />
            <span>Mayusculas</span>
          </label>
          <label class="switch">
            <input type="checkbox" v-model="numbers" />
            <span>Numeros</span>
          </label>
          <label class="switch">
            <input type="checkbox" v-model="symbols" />
            <span>Simbolos</span>
          </label>
        </div>

        <p v-if="!canGenerate" class="error" role="status">
          Selecciona al menos un conjunto de caracteres
        </p>
      </form>
    </section>

    <footer class="footer">
      <small>© {{ year }}</small>
    </footer>
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

.header {
  display: flex;
  justify-content: center;
}

.brand {
  display: flex;
  gap: 12px;
  align-items: center;
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

.brandText {
  display: grid;
  gap: 2px;
}

.title {
  margin: 0;
  font-size: 24px;
  line-height: 1.2;
}

.subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.78);
}

.panel {
  width: min(920px, calc(100vw - 32px));
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.06);
  box-shadow: 0 16px 60px rgba(0, 0, 0, 0.35);
  padding: 18px;
}

.output {
  display: grid;
  gap: 10px;
}

.label {
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.72);
}

.outputRow {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
  align-items: center;
}

.outputInput {
  width: 100%;
  padding: 12px 12px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(0, 0, 0, 0.18);
  color: rgba(255, 255, 255, 0.92);
}

.btn {
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.16);
  background: rgba(255, 255, 255, 0.12);
  cursor: pointer;
  transition: transform 80ms ease, background 120ms ease;
}

.btn:hover:enabled {
  background: rgba(255, 255, 255, 0.18);
}

.btn:active:enabled {
  transform: translateY(1px);
}

.btn:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.btnGhost {
  background: transparent;
}

.meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}

.chip {
  padding: 6px 10px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(0, 0, 0, 0.12);
  font-size: 13px;
}

.chipHint {
  color: rgba(255, 255, 255, 0.7);
}

.chip[data-tone='good'] {
  border-color: rgba(64, 214, 128, 0.35);
}

.chip[data-tone='ok'] {
  border-color: rgba(142, 189, 255, 0.35);
}

.chip[data-tone='warn'] {
  border-color: rgba(255, 196, 77, 0.35);
}

.chip[data-tone='bad'] {
  border-color: rgba(255, 102, 102, 0.35);
}

.divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.12);
  margin: 16px 0;
}

.controls {
  display: grid;
  gap: 12px;
}

.row {
  display: grid;
  gap: 8px;
}

.rangeRow {
  display: grid;
  grid-template-columns: 1fr 96px;
  gap: 12px;
  align-items: center;
}

.range {
  width: 100%;
}

.number {
  padding: 10px 10px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(0, 0, 0, 0.18);
}

.switches {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.switch {
  display: flex;
  gap: 10px;
  align-items: center;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(0, 0, 0, 0.12);
  padding: 10px 12px;
  border-radius: 12px;
}

.switch input {
  width: 16px;
  height: 16px;
}

.error {
  margin: 0;
  color: rgba(255, 180, 180, 0.95);
}

.footer {
  display: flex;
  justify-content: center;
  color: rgba(255, 255, 255, 0.65);
}

@media (max-width: 680px) {
  .outputRow {
    grid-template-columns: 1fr;
  }

  .rangeRow {
    grid-template-columns: 1fr;
  }

  .switches {
    grid-template-columns: 1fr;
  }
}
</style>
