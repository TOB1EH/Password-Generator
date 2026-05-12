<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import {
  ChevronDown,
  ChevronUp,
  Copy,
  Eye,
  EyeOff,
  LogOut,
  Monitor,
  Moon,
  Trash2,
  Sun,
} from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import {
  buildCharset,
  estimateStrengthBits,
  generatePassword,
} from '../lib/password.js'
import { generatePassphrase } from '../lib/passphrase.js'
import { supabase } from '../lib/supabase.js'
import { deriveKey, encryptData, decryptData } from '../lib/crypto.js'

const router = useRouter()
const username = ref('Administrador')

const year = new Date().getFullYear()

const mode = ref('password')

const length = ref(20)
const lower = ref(true)
const upper = ref(true)
const numbers = ref(true)
const symbols = ref(false)

const base = ref('')

const wordsCount = ref(4)
const passphraseCapitalize = ref(false)
const passphraseLang = ref('es')

const labelName = ref('')
const password = ref('')
const copyState = ref('idle')
const reveal = ref(false)

const theme = ref('system')
const history = ref([])
const historyOpen = ref(true)
const revealedIds = ref(new Set())

let sessionKey = null

const themeLabel = computed(() => {
  if (theme.value === 'light') return 'Claro'
  if (theme.value === 'dark') return 'Oscuro'
  return 'Sistema'
})

const HISTORY_LIMIT = 50

const charset = computed(() =>
  buildCharset({
    lower: lower.value,
    upper: upper.value,
    numbers: numbers.value,
    symbols: symbols.value,
  })
)

const strengthBits = computed(() => {
  if (mode.value === 'passphrase') {
    const estimatedChars = Math.max(1, wordsCount.value) * 5 +
      Math.max(0, wordsCount.value - 1)
    return estimateStrengthBits({
      length: estimatedChars,
      charsetSize: 2048,
    })
  }

  return estimateStrengthBits({ length: length.value, charsetSize: charset.value.length })
})

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

const canGenerate = computed(() => {
  if (mode.value === 'password') return charset.value.length > 0
  return true
})

function sanitizeBase(input) {
  return String(input ?? '').trim()
}

function applyBaseStrategy({ outLength, charsetValue }) {
  const b = sanitizeBase(base.value)
  if (!b) return null

  let kept = ''
  for (const ch of b) {
    if (charsetValue.includes(ch)) kept += ch
  }

  if (!kept) return null

  return kept.slice(0, outLength)
}

async function handleLogout() {
  await supabase.auth.signOut()
  sessionStorage.removeItem('pg_master_key')
  sessionKey = null
  router.push('/login')
}

function regenerate() {
  if (mode.value === 'passphrase') {
    try {
      password.value = generatePassphrase({
        wordsCount: wordsCount.value,
        separator: '-',
        capitalize: passphraseCapitalize.value,
        lang: passphraseLang.value,
      })
    } catch {
      password.value = ''
    }
    return
  }

  if (!canGenerate.value) {
    password.value = ''
    return
  }

  try {
    const targetLen = length.value
    const baseSeed = applyBaseStrategy({
      outLength: targetLen,
      charsetValue: charset.value,
    })

    let out = baseSeed ?? ''
    if (out.length < targetLen) {
      out += generatePassword({
        length: targetLen - out.length,
        charset: charset.value,
      })
    }
    password.value = out
  } catch {
    password.value = ''
  }
}

async function loadHistoryFromSupabase() {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session || !sessionKey) return

  const { data, error } = await supabase
    .from('password_history')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(HISTORY_LIMIT)

  if (error) {
    console.error('Error fetching history:', error)
    return
  }

  const decryptedHistory = []
  for (const row of data) {
    try {
      const decryptedValue = await decryptData(sessionKey, row.encrypted_value)
      decryptedHistory.push({
        id: row.id,
        ts: new Date(row.created_at).getTime(),
        label: row.label,
        kind: row.kind,
        value: decryptedValue
      })
    } catch (err) {
      console.error('Error decrypting row', row.id)
    }
  }
  history.value = decryptedHistory
}

async function generateAndStore() {
  const name = labelName.value.trim()
  if (!name) {
    labelName.value = ''
    document.getElementById('labelName')?.focus()
    return
  }

  const before = password.value
  regenerate()
  if (!password.value || password.value === before) return

  await addToHistory({
    label: name,
    kind: mode.value === 'passphrase' ? 'frase' : 'contrasena',
    value: password.value,
  })

  labelName.value = ''
}

async function addToHistory({ label, kind, value }) {
  if (!sessionKey) return

  try {
    const encrypted_value = await encryptData(sessionKey, value)
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) return

    const { data, error } = await supabase
      .from('password_history')
      .insert({
        user_id: session.user.id,
        label,
        kind,
        encrypted_value
      })
      .select()
      .single()

    if (error) throw error

    const entry = {
      id: data.id,
      ts: new Date(data.created_at).getTime(),
      kind,
      label,
      value,
    }

    history.value = [entry, ...history.value].slice(0, HISTORY_LIMIT)
  } catch (err) {
    console.error('Error adding to history', err)
  }
}

async function clearHistory() {
  history.value = []
  revealedIds.value = new Set()
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session) {
      await supabase
        .from('password_history')
        .delete()
        .eq('user_id', session.user.id)
    }
  } catch (err) {
    console.error('Error clearing history', err)
  }
}

async function deleteHistoryItem(id) {
  try {
    const { error } = await supabase
      .from('password_history')
      .delete()
      .eq('id', id)
    
    if (error) throw error
    
    history.value = history.value.filter(item => item.id !== id)
    revealedIds.value.delete(id)
  } catch (err) {
    console.error('Error deleting history item', err)
  }
}

function toggleReveal(id) {
  const s = new Set(revealedIds.value)
  if (s.has(id)) s.delete(id)
  else s.add(id)
  revealedIds.value = s
}

function isRevealed(id) {
  return revealedIds.value.has(id)
}

function maskValue(val) {
  return '\u2022'.repeat(Math.min(val.length, 128))
}

async function copyHistoryItem(item) {
  if (!item.value) return
  try {
    await navigator.clipboard.writeText(item.value)
  } catch {
    const el = document.createElement('textarea')
    el.value = item.value
    el.setAttribute('readonly', 'true')
    el.style.position = 'fixed'
    el.style.top = '-9999px'
    document.body.appendChild(el)
    el.select()
    document.execCommand('copy')
    document.body.removeChild(el)
  }
}

function applyTheme(next) {
  const root = document.documentElement
  root.dataset.theme = next
}

function cycleTheme() {
  const order = ['system', 'dark', 'light']
  const idx = Math.max(0, order.indexOf(theme.value))
  theme.value = order[(idx + 1) % order.length]
}

function formatTime(ts) {
  try {
    return new Intl.DateTimeFormat(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      day: '2-digit',
      month: '2-digit',
    }).format(new Date(ts))
  } catch {
    return ''
  }
}

async function copyToClipboard() {
  if (!password.value) return
  try {
    await navigator.clipboard.writeText(password.value)
    copyState.value = 'copied'
  } catch {
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

watch(
  [mode, length, lower, upper, numbers, symbols, base, wordsCount, passphraseCapitalize, passphraseLang],
  () => {
  regenerate()
  }
)

watch(historyOpen, (open) => {
  try {
    localStorage.setItem('pg_history_open', open ? '1' : '0')
  } catch {
    // ignore
  }
})

watch(theme, (t) => {
  try {
    localStorage.setItem('pg_theme', t)
  } catch {
    // ignore
  }
  applyTheme(t)
})

onMounted(async () => {
  try {
    const t = localStorage.getItem('pg_theme')
    if (t === 'light' || t === 'dark' || t === 'system') theme.value = t
  } catch {
    // ignore
  }

  applyTheme(theme.value)

  try {
    const open = localStorage.getItem('pg_history_open')
    if (open === '0') historyOpen.value = false
  } catch {
    // ignore
  }

  const { data: { session } } = await supabase.auth.getSession()
  if (!session) {
    router.push('/login')
    return
  }

  const masterPass = sessionStorage.getItem('pg_master_key')
  if (!masterPass) {
    // Si la sesión existe pero se perdió la clave de desencriptado (ej. cerró la pestaña pero la cookie duró)
    // forzamos al usuario a volver a loguearse para obtener la contraseña de la que derivamos la clave
    await handleLogout()
    return
  }

  try {
    sessionKey = await deriveKey(masterPass)
    await loadHistoryFromSupabase()
  } catch (err) {
    console.error('Error al inicializar sesión cifrada', err)
  }

  regenerate()
})
</script>
<template>
  <main class="page">
    <header class="header">
      <div class="brand">
        <div class="badge" aria-hidden="true">🔐</div>
        <div class="brandText">
          <h1 class="title">Password Generator</h1>
          <p class="subtitle">Genera contrasenas aleatorias seguras</p>
        </div>
      </div>

      <div class="header-actions">
        <button
          class="iconBtn"
          type="button"
          @click="cycleTheme"
          :aria-label="`Cambiar tema (actual: ${themeLabel})`"
          :title="`Cambiar tema (actual: ${themeLabel})`"
        >
          <Sun v-if="theme === 'light'" aria-hidden="true" class="iconSvg" :size="18" />
          <Moon v-else-if="theme === 'dark'" aria-hidden="true" class="iconSvg" :size="18" />
          <Monitor v-else aria-hidden="true" class="iconSvg" :size="18" />
        </button>
        <button
          class="iconBtn"
          type="button"
          @click="handleLogout"
          aria-label="Cerrar Sesion"
          title="Cerrar Sesion"
        >
          <LogOut aria-hidden="true" class="iconSvg" :size="18" />
        </button>
      </div>
    </header>

    <section class="panel" aria-label="Generador de contrasenas">
      <div class="tabs" role="tablist" aria-label="Modo">
        <button
          class="tab"
          type="button"
          role="tab"
          :aria-selected="mode === 'password'"
          @click="mode = 'password'"
        >
          Contrasena
        </button>
        <button
          class="tab"
          type="button"
          role="tab"
          :aria-selected="mode === 'passphrase'"
          @click="mode = 'passphrase'"
        >
          Frase
        </button>
      </div>

      <div class="output">
        <div class="labelRow">
          <label class="label" for="labelName">Nombre</label>
          <input
            id="labelName"
            class="text"
            type="text"
            v-model="labelName"
            placeholder="Ej: Mi cuenta de Google"
            autocomplete="off"
            spellcheck="false"
          />
          <p v-if="labelName && !labelName.trim()" class="error" role="status">
            Escribe un nombre para guardar
          </p>
        </div>

        <label class="label" for="password">Contrasena generada</label>
        <div class="outputRow">
          <div class="inputWrap">
            <input
              id="password"
              class="outputInput"
              :value="password"
              readonly
              autocomplete="off"
              spellcheck="false"
              :type="reveal ? 'text' : 'password'"
            />
            <button
              class="inputRevealBtn"
              type="button"
              @click="reveal = !reveal"
              :aria-pressed="reveal"
              :aria-label="reveal ? 'Ocultar' : 'Mostrar'"
              :title="reveal ? 'Ocultar' : 'Mostrar'"
            >
              <EyeOff v-if="reveal" aria-hidden="true" :size="18" />
              <Eye v-else aria-hidden="true" :size="18" />
            </button>
          </div>
          <button class="btn" type="button" @click="generateAndStore" :disabled="!canGenerate">
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
        </div>
      </div>

      <div class="divider" role="separator" aria-orientation="horizontal" />

      <form class="controls" @submit.prevent>
        <div v-if="mode === 'password'" class="row">
          <div class="field">
            <label class="label" for="length">Longitud</label>
            <div class="rangeRow">
              <input
                id="length"
                class="range"
                type="range"
                min="8"
                max="128"
                step="1"
                v-model.number="length"
              />
              <input
                class="number"
                type="number"
                min="8"
                max="128"
                step="1"
                v-model.number="length"
                aria-label="Longitud exacta"
              />
            </div>
          </div>
        </div>

        <div v-if="mode === 'password'" class="row switches">
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

        <div v-if="mode === 'password'" class="row">
          <label class="label" for="base">Clave base (opcional)</label>
          <input
            id="base"
            class="text"
            type="text"
            v-model="base"
            placeholder="Ej: MiClaveBase"
            autocomplete="off"
            spellcheck="false"
          />
          <p class="help">
            La contrasena empezara con tu clave base (filtrada al set elegido)
            y se completara con caracteres aleatorios
          </p>
        </div>

        <div v-if="mode === 'passphrase'" class="row">
          <div class="field">
            <label class="label" for="words">Cantidad de palabras</label>
            <div class="rangeRow">
              <input
                id="words"
                class="range"
                type="range"
                min="2"
                max="20"
                step="1"
                v-model.number="wordsCount"
              />
              <input
                class="number"
                type="number"
                min="2"
                max="20"
                step="1"
                v-model.number="wordsCount"
                aria-label="Cantidad exacta"
              />
            </div>
          </div>

          <label class="switch">
            <input type="checkbox" v-model="passphraseCapitalize" />
            <span>Empezar palabras con mayuscula</span>
          </label>
          <label class="label" for="passphraseLang">Idioma</label>
          <div class="tabLangRow">
            <button
              class="tabLang"
              type="button"
              :class="{ tabLangActive: passphraseLang === 'es' }"
              @click="passphraseLang = 'es'"
              :aria-pressed="passphraseLang === 'es'"
            >
              Espanol
            </button>
            <button
              class="tabLang"
              type="button"
              :class="{ tabLangActive: passphraseLang === 'en' }"
              @click="passphraseLang = 'en'"
              :aria-pressed="passphraseLang === 'en'"
            >
              English
            </button>
          </div>
          <p class="help">Separador: guion</p>
        </div>

        <p v-if="mode === 'password' && !canGenerate" class="error" role="status">
          Selecciona al menos un conjunto de caracteres
        </p>
      </form>

      <div class="history" aria-label="Historial">
        <div class="historyHead">
          <div class="historyTitle">
            <div class="label">Historial</div>
            <div class="historyHint">Se guarda cifrado en Supabase</div>
          </div>

          <div class="historyActions">
            <button
              class="iconBtn iconBtnInline"
              type="button"
              @click="historyOpen = !historyOpen"
              :aria-expanded="historyOpen"
              aria-controls="historyList"
              :title="historyOpen ? 'Contraer' : 'Expandir'"
              :aria-label="historyOpen ? 'Contraer historial' : 'Expandir historial'"
            >
              <ChevronUp v-if="historyOpen" aria-hidden="true" class="iconSvg" :size="18" />
              <ChevronDown v-else aria-hidden="true" class="iconSvg" :size="18" />
            </button>
            <button class="btn btnGhost" type="button" @click="clearHistory" :disabled="history.length === 0">
              Limpiar
            </button>
          </div>
        </div>

        <ul v-show="historyOpen" id="historyList" class="historyList">
          <li v-for="h in history" :key="h.id" class="historyItem">
            <div class="historyMeta">
              <span class="historyTime">{{ formatTime(h.ts) }}</span>
            </div>
            <div class="historyLabel">{{ h.label }}</div>
            <div class="historyRow">
              <span class="historyValue">
                {{ isRevealed(h.id) ? h.value : maskValue(h.value) }}
              </span>
              <button
                class="historyIconBtn"
                type="button"
                @click="toggleReveal(h.id)"
                :aria-label="isRevealed(h.id) ? 'Ocultar' : 'Mostrar'"
                :title="isRevealed(h.id) ? 'Ocultar' : 'Mostrar'"
              >
                <EyeOff v-if="isRevealed(h.id)" aria-hidden="true" :size="16" />
                <Eye v-else aria-hidden="true" :size="16" />
              </button>
               <button
                 class="historyIconBtn"
                 type="button"
                 @click="copyHistoryItem(h)"
                 :aria-label="'Copiar'"
                 :title="'Copiar'"
               >
                 <Copy aria-hidden="true" :size="16" />
               </button>
               <button
                 class="historyIconBtn historyIconBtnDelete"
                 type="button"
                 @click="deleteHistoryItem(h.id)"
                 :aria-label="'Eliminar'"
                 :title="'Eliminar'"
               >
                 <Trash2 aria-hidden="true" :size="16" />
               </button>
            </div>
          </li>
        </ul>
      </div>
    </section>

    <footer class="footer">
      <small>&copy; {{ year }} Tobias Funes | Construido con OpenCode & Plannotator</small>
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
  position: relative;
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
  color: var(--fg-muted);
}

.panel {
  width: min(920px, calc(100vw - 32px));
  border: 1px solid var(--border);
  border-radius: 18px;
  background: var(--surface);
  box-shadow: 0 16px 60px rgba(0, 0, 0, 0.35);
  padding: 18px;
}

.tabs {
  display: inline-flex;
  gap: 6px;
  padding: 6px;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--surface-2);
  margin-bottom: 14px;
}

.tab {
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid transparent;
  background: transparent;
  cursor: pointer;
}

.tab[aria-selected='true'] {
  border-color: var(--border-strong);
  background: var(--btn);
}

.output {
  display: grid;
  gap: 10px;
}

.labelRow {
  display: grid;
  gap: 6px;
}

.label {
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--fg-muted);
}

.outputRow {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto auto;
  gap: 10px;
  align-items: center;
}

.inputWrap {
  position: relative;
  display: flex;
  align-items: stretch;
}

.outputInput {
  width: 100%;
  min-width: 0;
  padding: 12px 44px 12px 12px;
  border-radius: 12px;
  border: 1px solid var(--border-strong);
  background: var(--surface-3);
  color: var(--fg);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  overflow-x: auto;
}

.inputRevealBtn {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: var(--fg-dim);
  cursor: pointer;
  padding: 4px;
  display: grid;
  place-items: center;
  border-radius: 6px;
  transition: color 120ms ease;
}

.inputRevealBtn:hover {
  color: var(--fg);
}

.btn {
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--border-strong);
  background: var(--btn);
  cursor: pointer;
  transition: transform 80ms ease, background 120ms ease;
}

.btn:hover:enabled {
  background: var(--btn-hover);
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

.iconBtn {
  border: 1px solid var(--border);
  background: var(--surface-2);
  color: var(--fg);
  border-radius: 12px;
  padding: 10px 10px;
  cursor: pointer;
  transition: transform 80ms ease, background 120ms ease;
}

.iconBtn:hover:enabled {
  background: var(--btn-hover);
}

.iconBtn:active:enabled {
  transform: translateY(1px);
}

.iconBtnInline {
  padding: 8px 10px;
}

.iconSvg {
  display: block;
}

.header-actions {
  position: absolute;
  right: 0;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  gap: 8px;
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
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  font-size: 13px;
}

.chipHint {
  color: var(--fg-dim);
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
  background: var(--border);
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
  border: 1px solid var(--border-strong);
  background: var(--surface-3);
}

.text {
  width: 100%;
  padding: 10px 10px;
  border-radius: 12px;
  border: 1px solid var(--border-strong);
  background: var(--surface-3);
}

.help {
  margin: 0;
  color: var(--fg-dim);
  font-size: 13px;
}

.switches {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.switch {
  display: flex;
  gap: 10px;
  align-items: center;
  border: 1px solid var(--border);
  background: var(--surface-2);
  padding: 10px 12px;
  border-radius: 12px;
}

.switch input {
  width: 16px;
  height: 16px;
}

.tabLangRow {
  display: inline-flex;
  gap: 6px;
  padding: 4px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface-2);
}

.tabLang {
  padding: 6px 12px;
  border-radius: 8px;
  border: 1px solid transparent;
  background: transparent;
  cursor: pointer;
  font-size: 13px;
  color: var(--fg-dim);
  transition: background 120ms ease, color 120ms ease;
}

.tabLangActive {
  background: var(--btn);
  color: var(--fg);
  border-color: var(--border-strong);
}

.error {
  margin: 0;
  color: rgba(255, 180, 180, 0.95);
  font-size: 13px;
}

.history {
  margin-top: 16px;
  border-top: 1px solid var(--border);
  padding-top: 16px;
  display: grid;
  gap: 12px;
  min-width: 0;
}

.historyHead {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.historyTitle {
  display: grid;
  gap: 4px;
}

.historyActions {
  display: inline-flex;
  gap: 8px;
  align-items: center;
}

.historyHint {
  color: var(--fg-dim);
  font-size: 13px;
}

.historyList {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 8px;
}

.historyItem {
  border: 1px solid var(--border);
  background: var(--surface-2);
  border-radius: 12px;
  padding: 10px 12px;
  min-width: 0;
  overflow: hidden;
}

.historyMeta {
  display: flex;
  gap: 10px;
  color: var(--fg-dim);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.historyLabel {
  font-weight: 600;
  font-size: 15px;
  margin: 2px 0 6px;
  color: var(--fg);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.historyRow {
  display: flex;
  gap: 6px;
  align-items: center;
  min-width: 0;
}

.historyValue {
  flex: 1;
  min-width: 0;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  overflow-x: auto;
  white-space: nowrap;
  color: var(--fg);
  font-size: 14px;
}

.historyIconBtn {
  flex-shrink: 0;
  background: none;
  border: 1px solid var(--border);
  color: var(--fg-dim);
  cursor: pointer;
  padding: 4px;
  display: grid;
  place-items: center;
  border-radius: 6px;
  transition: color 120ms ease, background 120ms ease;
}

.historyIconBtn:hover {
  color: var(--fg);
  background: var(--btn);
}

.historyIconBtnDelete:hover {
  color: rgba(255, 102, 102, 0.95);
  background: rgba(255, 102, 102, 0.15);
}

.footer {
  display: flex;
  justify-content: center;
  color: var(--fg-dim);
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
