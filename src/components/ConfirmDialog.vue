<script setup>
import { AlertTriangle } from 'lucide-vue-next'

defineProps({
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  open: {
    type: Boolean,
    default: false,
  },
  dangerous: {
    type: Boolean,
    default: false,
  },
  confirmText: {
    type: String,
    default: 'Confirmar',
  },
  cancelText: {
    type: String,
    default: 'Cancelar',
  },
})

const emit = defineEmits(['confirm', 'cancel'])

function handleConfirm() {
  emit('confirm')
}

function handleCancel() {
  emit('cancel')
}

function handleBackdropClick(e) {
  if (e.target === e.currentTarget) {
    handleCancel()
  }
}
</script>

<template>
  <div v-if="open" class="backdrop" @click="handleBackdropClick">
    <div class="dialog" role="dialog" aria-modal="true">
      <div class="dialogHead" v-if="dangerous">
        <AlertTriangle aria-hidden="true" :size="20" class="warningIcon" />
        <h2 class="dialogTitle">{{ title }}</h2>
      </div>
      <h2 v-else class="dialogTitle">{{ title }}</h2>

      <p class="dialogMessage">{{ message }}</p>

      <div class="dialogActions">
        <button
          type="button"
          class="btn btnCancel"
          @click="handleCancel"
        >
          {{ cancelText }}
        </button>
        <button
          type="button"
          :class="['btn', { btnDangerous: dangerous }]"
          @click="handleConfirm"
        >
          {{ confirmText }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: grid;
  place-items: center;
  z-index: 9999;
  padding: 20px;
}

.dialog {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
  padding: 24px;
  max-width: 380px;
  width: 100%;
  display: grid;
  gap: 16px;
}

.dialogHead {
  display: flex;
  gap: 12px;
  align-items: center;
}

.warningIcon {
  color: rgba(255, 102, 102, 0.95);
  flex-shrink: 0;
}

.dialogTitle {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--fg);
}

.dialogMessage {
  margin: 0;
  color: var(--fg-muted);
  font-size: 14px;
  line-height: 1.5;
}

.dialogActions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.btn {
  padding: 10px 16px;
  border-radius: 10px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: var(--fg);
  cursor: pointer;
  font-weight: 500;
  font-size: 14px;
  transition: background 120ms ease, transform 80ms ease;
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

.btnCancel {
  background: var(--surface-2);
}

.btnDangerous {
  background: rgba(255, 102, 102, 0.25);
  border-color: rgba(255, 102, 102, 0.35);
  color: rgba(255, 180, 180, 0.95);
}

.btnDangerous:hover:enabled {
  background: rgba(255, 102, 102, 0.35);
}
</style>
