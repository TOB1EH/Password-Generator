# Plan por fases: Password Generator (Vue 3 + Vite)

Contexto (según `planning.md`): objetivo es un generador de contraseñas seguras.

## [ ] Supuestos y notas

- [x] El repo objetivo es `https://github.com/TOB1EH/Password-Generator.git` y usa Vue 3 + Vite
- [ ] La generación se hace del lado del cliente usando `crypto.getRandomValues`
- [ ] El historial, temas y preferencias se persisten en `localStorage` hasta que Login/Logout requiera backend

## [x] Fase 1: Estructura + Auto-deploy

### [x] Objetivo

- [x] Tener base del proyecto lista, calidad mínima y deploy automático

### [x] Alcance

- [x] Scaffold Vite (Vue 3), layout base, scripts `dev/build/preview`
- [x] Config de deploy para GitHub Pages (Actions)

### [x] Criterios de aceptación

- [x] `npm install` y `npm run dev` funcionan
- [x] `npm run build` genera artefactos
- [x] Deploy automático publica por push a `main`

### [x] Verificación

- [x] `npm run build` local
- [x] Workflow de Pages en `.github/workflows/deploy.yml`

### [x] Estado

- [x] Fase ejecutada en este workspace

## [x] Fase 2: Generador estilo Bitwarden (MVP)

### [x] Objetivo

- [x] Generar contraseña aleatoria con configuración básica y UX clara

### [x] Alcance

- [x] UI profesional y simple con preview, Generar y Copiar
- [x] Longitud y flags (mayúsculas, minúsculas, números, símbolos)
- [x] Indicador de fuerza (heurístico) y validaciones
- [x] Longitud minima 8 caracteres

### [x] Criterios de aceptación

- [x] Usa `crypto.getRandomValues` (no `Math.random`)
- [x] Copiar funciona y muestra feedback

### [ ] Verificación

- [x] Probar longitudes y combinaciones
- [x] Probar copiar en desktop y mobile

### [ ] Estado

- [x] Implementado en el código
- [x] Publicado en GitHub Pages
- [x] Probado en GitHub Pages

## [x] Fase 3: Opciones con clave base y ajustes

### [x] Objetivo

- [x] Tomar una clave base y derivar variantes

### [x] Alcance

- [x] Campo de clave base opcional
- [x] Agregar números, agregar símbolos, modificar longitud
- [x] Definir reglas de derivación (determinística o aleatoria)

### [ ] Estado

- [x] Iniciada

### [x] Criterios de aceptación

- [x] Respeta longitud y composición
- [x] UX explica si es determinístico o aleatorio

### [ ] Verificación

- [ ] Base corta/larga, con y sin espacios, con especiales

## [x] Fase 4: Modo diccionario (frases)

### [x] Objetivo

- [x] Generar passphrases con palabras aleatorias

### [x] Alcance

- [x] Selector de cantidad de palabras
- [x] Diccionario embebido o importado (definir idioma y tamaño)
- [x] Separador por guiones (por defecto) y opción de capitalización

### [ ] Estado

- [x] Iniciada
- [x] Implementada

### [x] Criterios de aceptación

- [x] Aleatorio criptográficamente seguro
- [x] Frases separadas por guiones
- [x] Parametro para empezar con mayuscula o no
- [x] Performance razonable

### [ ] Verificación

- [ ] Probar mínimo y máximo de palabras
- [ ] Probar en mobile

## [ ] Fase 5: Flujo de generación y copiado (pulido)

### [ ] Objetivo

- [ ] Completar UX de acciones principales

### [ ] Alcance

- [ ] Generar consistente para ambos modos
- [ ] Estados de copiar (éxito/fallo)
- [ ] Accesibilidad (foco, labels, aria, teclado)

### [ ] Criterios de aceptación

- [ ] Accesible por teclado
- [ ] Estados no dependen solo de color

### [ ] Verificación

- [ ] Navegación con Tab
- [ ] Lighthouse si está disponible

## [ ] Fase 6: Tema claro/oscuro e historial

### [ ] Objetivo

- [ ] Personalización y trazabilidad local

### [ ] Alcance

- [ ] Toggle de tema (opcional: respeta `prefers-color-scheme`)
- [ ] Historial con timestamps y opción de limpiar
- [ ] Persistencia en `localStorage`

### [ ] Criterios de aceptación

- [ ] Tema persiste entre sesiones
- [ ] Historial con límite para evitar crecimiento infinito

### [ ] Verificación

- [ ] Recargar y confirmar persistencia
- [ ] Generar muchos items y confirmar límite

## [ ] Fase 7: Revelar/ocultar contraseña

### [ ] Objetivo

- [ ] Ocultar el valor mostrado con asteriscos

### [ ] Alcance

- [ ] Toggle Mostrar/Ocultar
- [ ] Definir estado por defecto (privacidad)

### [ ] Criterios de aceptación

- [ ] Ocultar no rompe copiar
- [ ] No filtra el valor por UI secundaria

### [ ] Verificación

- [ ] Copiar con ambos estados

## [ ] Fase 8: Login/Logout

### [ ] Objetivo

- [ ] Autenticación y sesión

### [ ] Preguntas

- [ ] Proveedor (Firebase/Auth0/Supabase/propio) o login local
- [ ] Qué se protege (historial, preferencias, sincronización)
- [ ] Como administrar usuario administrador y seguridad en GitHub Pages

### [ ] Alcance

- [ ] UI de login/logout
- [ ] Estado de sesión y guardas
- [ ] Persistencia remota si hay backend

### [ ] Criterios de aceptación

- [ ] Login/logout funciona en deploy
- [ ] Datos sensibles minimizados en cliente

### [ ] Verificación

- [ ] Probar flujo completo en producción

## [ ] Riesgos y decisiones pendientes

- [ ] Host de auto-deploy (GitHub Pages vs Netlify/Vercel)
- [ ] Definir “misma contraseña” (determinística vs aleatoria desde base)
- [ ] Definir idioma y tamaño del diccionario
- [ ] Definir alcance real de Login/Logout
