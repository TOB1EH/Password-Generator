Actua como Ingeniero Senior (Vue 3).
Path: /home/tobias/Documentos/OneDrive/workSpace/SOA/practico_opencode/password_generator/
Repo: https://github.com/TOB1EH/Password-Generator.git. Usa Vue 3 + Vite.
Objetivo: Generador de contrasenas seguras aleatorias.

Fases implementadas:
1- Estructura + Auto-deploy
2- Generador de contrasenas (MVP, estilo BitWarden)
3- Clave base opcional + longitud configurable
4- Modo frases con diccionario y cantidad de palabras
5- Botones generar/copiar
6- Temas claro/oscuro + historial persistente
7- Revelar/ocultar contrasena
8- Login/Logout (simulado)

Mejoras agregadas post-fases:
- Boton de mostrar/ocultar dentro del campo de contrasena
- Clave base de aplicacion automatica (sin necesidad de checkbox)
- Campo "Nombre" obligatorio antes de generar (etiqueta en historial)
- Historial con nombre visible + contrasena mostrable/ocultable individualmente
- Boton copiar en cada entrada del historial
- Selector de idioma es/en para frases
- Tema "system" respeta prefers-color-scheme
- Temas migrados a tokens CSS para contraste correcto
- Historial colapsable y persistente
- IDs de historial con crypto.getRandomValues
- Iconos SVG con lucide-vue-next (sin emojis)
