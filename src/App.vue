<script setup>
const year = new Date().getFullYear()
</script>

<template>
  <main class="page">
    <header class="header">
      <h1 class="title">Password Generator</h1>
      <p class="subtitle">Base del proyecto (Vue 3 + Vite)</p>
    </header>

    <section class="card">
      <p>
        Fase 1 lista: proyecto inicializado y listo para desplegar.
      </p>
      <p class="hint">
        Siguiente: implementar el generador (Fase 2).
      </p>
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
  padding: 24px;
}

.header {
  display: grid;
  gap: 6px;
}

.title {
  margin: 0;
  font-size: 28px;
  line-height: 1.2;
}

.subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.8);
}

.card {
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.06);
  padding: 16px;
  max-width: 520px;
}

.hint {
  margin: 10px 0 0;
  color: rgba(255, 255, 255, 0.8);
}

.footer {
  color: rgba(255, 255, 255, 0.7);
}
</style>
