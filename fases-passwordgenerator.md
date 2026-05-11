# Plan por fases: Password Generator (Vue 3 + Vite)

Contexto (según `planning.md`): objetivo es un generador de contraseñas seguras. Este documento solo define plan; no implementa.

## Supuestos y notas

- El repo objetivo es `https://github.com/TOB1EH/Password-Generator.git` y usa Vue 3 + Vite. En este workspace todavía no se observan los archivos del proyecto.
- La generación se hace del lado del cliente (navegador) usando `crypto.getRandomValues`.
- El historial, temas y preferencias se persisten en `localStorage` (hasta que Login/Logout requiera backend).

## Fase 1: Estructura + Auto-deploy

Objetivo: tener base del proyecto lista, calidad mínima y deploy automático.

Alcance:

- Estructura de proyecto Vite (Vue 3), rutas si aplica, y layout base.
- Estándares de código: formatter/lint si el repo ya los usa (sin introducir herramientas innecesarias).
- Auto-deploy (por definir según hosting): GitHub Pages (Actions), Netlify o Vercel.

Criterios de aceptación:

- `npm install` y `npm run dev` funcionan.
- `npm run build` genera artefactos.
- Deploy automático publica el sitio en cada push a la rama principal.

Verificación:

- Ejecutar `npm run build` local.
- Confirmar workflow de CI/CD en el proveedor elegido.

Estado (workspace actual): fase ejecutada. Se agregó el scaffold Vue 3 + Vite y un workflow de GitHub Pages.

## Fase 2: Generador estilo Bitwarden (MVP)

Objetivo: generar una contraseña aleatoria con configuración básica, UX clara y segura.

Alcance:

- UI simple: input/preview de contraseña, botón “Generar”, botón “Copiar”.
- Parámetros MVP: longitud, incluir mayúsculas, minúsculas, números, símbolos.
- Indicador de fuerza aproximado (heurístico) y validaciones (ej. longitud mínima).

Criterios de aceptación:

- Genera contraseñas usando `crypto.getRandomValues`.
- No repite sesgos obvios (sin `Math.random`).
- Copiar muestra feedback (toast/estado) y funciona en navegadores modernos.

Verificación:

- Probar múltiples longitudes y combinaciones de flags.
- Probar copiar en desktop y mobile.

## Fase 3: Opciones “misma base” y ajustes (longitud y composición)

Objetivo: soportar el flujo de “tomar una clave base” y derivar variantes.

Alcance:

- Campo “clave base” opcional.
- Controles: agregar números, agregar símbolos, ajustar longitud.
- Reglas claras para derivación (determinística o no): definir comportamiento esperado.

Criterios de aceptación:

- Si se provee clave base, el sistema genera una variante que respeta longitud y composición.
- UX explica si el resultado es determinístico o aleatorio.

Verificación:

- Casos: base corta/larga, con/ sin espacios, con caracteres especiales.

## Fase 4: Modo diccionario (frases)

Objetivo: generar passphrases con palabras aleatorias.

Alcance:

- Selector de cantidad de palabras.
- Lista/diccionario embebido o importado (definir idioma y tamaño).
- Separador configurable (espacio, guion, etc.) y opción de capitalización.

Criterios de aceptación:

- Genera frases con `N` palabras de forma aleatoria criptográficamente segura.
- Performance razonable (sin bloqueos) con diccionario moderado.

Verificación:

- Probar `N` mínimo/máximo.
- Probar en mobile.

## Fase 5: Botones y flujo de generación/copiado (pulido)

Objetivo: completar UX de acciones principales.

Alcance:

- Botón “Generar” consistente para ambos modos.
- Botón “Copiar” y estados: éxito/fallo.
- Accesibilidad: foco, labels, aria, navegación por teclado.

Criterios de aceptación:

- Todas las acciones son accesibles por teclado.
- Mensajes de estado no dependen solo del color.

Verificación:

- Tab traversal.
- Lighthouse (si está disponible en el proyecto).

## Fase 6: Temas claro/oscuro + historial

Objetivo: personalización y trazabilidad local.

Alcance:

- Toggle de tema (respeta `prefers-color-scheme` si aplica).
- Historial de contraseñas/passphrases generadas (con timestamps), con opción de limpiar.
- Persistencia en `localStorage`.

Criterios de aceptación:

- El tema persiste entre sesiones.
- El historial se limita (ej. 25-100 items) para evitar crecimiento infinito.

Verificación:

- Recargar página y confirmar persistencia.
- Generar muchos items y confirmar límite.

## Fase 7: Revelar/ocultar contraseña (asteriscos)

Objetivo: permitir ocultar el valor mostrado.

Alcance:

- Toggle “Mostrar/Ocultar”.
- Por defecto oculto si se decide priorizar privacidad.

Criterios de aceptación:

- Ocultar no rompe copiar.
- El campo no filtra accidentalmente por logs o UI secundaria.

Verificación:

- Probar copiar con ambos estados.

## Fase 8: Login/Logout

Objetivo: autenticación y sesión.

Preguntas a resolver antes de implementar:

- ¿Proveedor? (Firebase/Auth0/supabase/propio) o solo “login” local.
- ¿Qué se protege? (historial, preferencias, sincronización).

Alcance (tentativo):

- UI de login/logout.
- Estado de sesión y guardas si hay secciones protegidas.
- Si hay backend: persistencia remota de historial/preferencias.

Criterios de aceptación:

- Login/logout funciona en entorno de deploy.
- Datos sensibles no se exponen en cliente más allá de lo inevitable.

Verificación:

- Probar flujo completo en producción (URL del deploy).

## Riesgos y decisiones pendientes

- Host de auto-deploy (GitHub Pages vs Netlify/Vercel).
- Definición exacta de “misma contraseña” (determinística vs aleatoria a partir de base).
- Idioma/tamaño del diccionario para passphrases.
- Alcance real de Login/Logout (requiere definir backend o proveedor).
