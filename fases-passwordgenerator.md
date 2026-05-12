# Plan por fases: Password Generator (Vue 3 + Vite)

Contexto (según `planning.md`): objetivo es un generador de contraseñas seguras.

## [ ] Supuestos y notas

- [x] El repo objetivo es `https://github.com/TOB1EH/Password-Generator.git` y usa Vue 3 + Vite
- [x] La generación se hace del lado del cliente usando `crypto.getRandomValues`
- [x] El historial, temas y preferencias se persisten en `localStorage` hasta que Login/Logout requiera backend

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

- [x] Base corta/larga, con y sin espacios, con especiales

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

### [x] Verificación

- [x] Probar mínimo y máximo de palabras
- [x] Probar en mobile

## [x] Fase 5: Flujo de generación y copiado (pulido)

### [x] Objetivo

- [x] Completar UX de acciones principales

### [x] Alcance

- [x] Generar consistente para ambos modos
- [x] Estados de copiar (éxito/fallo)
- [x] Accesibilidad (foco, labels, aria, teclado)

### [x] Criterios de aceptación

- [x] Accesible por teclado
- [x] Estados no dependen solo de color

### [x] Verificación

- [x] Navegación con Tab
- [ ] Lighthouse si está disponible

### [ ] Estado

- [x] Implementada

## [x] Fase 6: Tema claro/oscuro e historial

### [x] Objetivo

- [x] Personalización y trazabilidad local

### [x] Alcance

- [x] Toggle de tema (opcional: respeta `prefers-color-scheme`)
- [x] Historial con timestamps y opción de limpiar
- [x] Persistencia en `localStorage`

### [x] Criterios de aceptación

- [x] Tema persiste entre sesiones
- [x] Historial con límite para evitar crecimiento infinito

### [x] Verificación

- [x] Recargar y confirmar persistencia
- [x] Generar muchos items y confirmar límite

### [ ] Estado

- [x] Implementada

## [x] Fase 7: Revelar/ocultar contraseña

### [x] Objetivo

- [x] Ocultar el valor mostrado con asteriscos

### [x] Alcance

- [x] Toggle Mostrar/Ocultar
- [x] Definir estado por defecto (privacidad)

### [x] Criterios de aceptación

- [x] Ocultar no rompe copiar
- [x] No filtra el valor por UI secundaria

### [x] Verificación

- [x] Copiar con ambos estados

### [ ] Estado

- [x] Implementada

## [x] Fase 8: Login/Logout

### [x] Objetivo

- [x] Autenticación y sesión

### [x] Preguntas

- [x] Proveedor (Firebase/Auth0/Supabase/propio) o login local: Login local simulado para GitHub Pages
- [x] Qué se protege (historial, preferencias, sincronización): El generador completo se protege con una vista de Login
- [x] Como administrar usuario administrador y seguridad en GitHub Pages: Se simula guardando un token ficticio en localStorage

### [x] Alcance

- [x] UI de login/logout
- [x] Estado de sesión y guardas
- [x] Persistencia remota si hay backend: Solo cliente (localStorage)

### [x] Criterios de aceptación

- [x] Login/logout funciona en deploy
- [x] Datos sensibles minimizados en cliente

### [x] Verificación

- [x] Probar flujo completo en producción

## [ ] Fase 9: Persistencia con Supabase (Backend/BBDD)

### [ ] Objetivo

- [ ] Implementar el almacenamiento de nuevas contraseñas en una base de datos relacional PostgreSQL en Supabase (la base de datos arrancará vacía, no se migrarán los datos de prueba de `localStorage`).
- [ ] Implementar autenticación real para un único usuario administrador.

### [ ] Alcance

- [ ] Configurar el cliente de Supabase en el proyecto Vue.
- [ ] Autenticación de Supabase (Login real, protección de rutas).
- [ ] Crear tabla de historial de contraseñas en Supabase (con RLS para el admin).
- [ ] Lógica de cifrado simétrico: las contraseñas deben cifrarse/desencriptarse en el cliente (usando una clave maestra o derivada) antes de guardarse en Supabase, para que ni siquiera teniendo acceso a la DB se puedan leer en texto plano.

### [ ] Criterios de aceptación

- [ ] El usuario ingresa con credenciales reales (administrador).
- [ ] El historial se sincroniza y se lee desde Supabase.
- [ ] Las contraseñas en la base de datos están cifradas ("hasheadas" o encriptadas reversiblemente si se necesitan ver, ver notas).
- [ ] Sigue funcionando en GitHub Pages.

### [ ] Verificación

- [ ] Verificar inserción, lectura y borrado en el dashboard de Supabase.
- [ ] Probar el cierre de sesión y protección de ruta raíz con sesión real.

## [x] Fase 9: Persistencia con Supabase (Backend/BBDD)

### [x] Objetivo

- [x] Implementar el almacenamiento de nuevas contraseñas en una base de datos relacional PostgreSQL en Supabase (la base de datos arrancará vacía, no se migrarán los datos de prueba de `localStorage`).
- [x] Implementar autenticación real para un único usuario administrador.

### [x] Alcance

- [x] Configurar el cliente de Supabase en el proyecto Vue.
- [x] Autenticación de Supabase (Login real, protección de rutas).
- [x] Crear tabla de historial de contraseñas en Supabase (con RLS para el admin).
- [x] Lógica de cifrado simétrico: las contraseñas deben cifrarse/desencriptarse en el cliente (usando una clave maestra o derivada) antes de guardarse en Supabase, para que ni siquiera teniendo acceso a la DB se puedan leer en texto plano.

### [x] Criterios de aceptación

- [x] El usuario ingresa con credenciales reales (administrador).
- [x] El historial se sincroniza y se lee desde Supabase.
- [x] Las contraseñas en la base de datos están cifradas ("hasheadas" o encriptadas reversiblemente si se necesitan ver, ver notas).
- [x] Sigue funcionando en GitHub Pages.

### [x] Verificación

- [x] Verificar inserción, lectura y borrado en el dashboard de Supabase.
- [x] Probar el cierre de sesión y protección de ruta raíz con sesión real.

## [ ] Fase 10: Mejoras de Frontend

### [ ] Objetivo

- [ ] Mejorar la experiencia visual y funcionalidad del generador de contraseñas.

### [ ] Alcance

- [ ] Actualizar footer con créditos de herramientas usadas (OpenCode, Plannotator) y nombre del desarrollador (Tobias Funes).
- [ ] Mejorar el logo de la aplicación (cambiar de "PG" simple a un diseño más atractivo con símbolos, gráficos o librerías).
- [ ] Actualizar mensajes obsoletos en el historial (quitar "Se guarda solo en este navegador" ya que ahora usa Supabase).
- [ ] Implementar eliminación individual de contraseñas en el historial (botón eliminar por entrada).

### [ ] Criterios de aceptación

- [ ] Footer muestra: nombre del desarrollador, herramientas usadas y año actual.
- [ ] Logo es visualmente atractivo y diferente a solo texto "PG".
- [ ] Mensajes del historial reflejan que se usa base de datos Supabase.
- [ ] Cada entrada del historial tiene un botón para eliminar esa contraseña específica.

### [ ] Verificación

- [ ] Probar eliminación individual sin afectar otras contraseñas.
- [ ] Verificar que los cambios se reflejan correctamente en Supabase.

## [ ] Riesgos y decisiones pendientes

- [x] Host de auto-deploy: GitHub Pages
- [ ] Definir “misma contraseña” (determinística vs aleatoria desde base)
- [x] Definir idioma y tamaño del diccionario: Inglés y español (diccionario grande)
- [x] Definir alcance real de Login/Logout: Crear usuario administrador unicamente, es una plataforma personal donde solo yo puedo loguearme.
