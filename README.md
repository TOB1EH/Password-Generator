# Password Generator

Generador de contraseñas y frases de acceso seguras, cifradas y profesionales. Construido con Vue 3, Vite, Supabase y Web Crypto API.

> Este proyecto fue desarrollado desde cero utilizando **OpenCode** y **Plannotator** como agentes de IA para asistencia en desarrollo, planificación y revisión de código.

**Sitio en vivo**: [Password Generator en GitHub Pages](https://tob1eh.github.io/Password-Generator/)

---

## Stack Tecnológico

### Tecnologías principales

[![Vue 3](https://img.shields.io/badge/Vue%203-35495e?style=for-the-badge&logo=vue.js)](https://vuejs.org)
[![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev)
[![Supabase](https://img.shields.io/badge/Supabase-181818?style=for-the-badge&logo=supabase&logoColor=3ECF8E)](https://supabase.com)
[![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-222222?style=for-the-badge&logo=github&logoColor=white)](https://pages.github.com)

### Herramientas de desarrollo y planificación

[![OpenCode](https://img.shields.io/badge/OpenCode-Agente%20IA-FF6B35?style=for-the-badge)](https://opencode.ai)
[![Plannotator](https://img.shields.io/badge/Plannotator-Revision%20y%20Anotaciones-4A90E2?style=for-the-badge)](https://plannotator.ai)

---

## Características principales

- **Generador de contraseñas**: Crea contraseñas aleatorias configurables (longitud, mayúsculas, minúsculas, números, símbolos)
- **Generador de frases**: Crea passphrases usando palabras aleatorias del diccionario (español e inglés)
- **Clave base opcional**: Personaliza el inicio de la contraseña con una clave base
- **Indicador de fuerza**: Estima la entropía en bits (débil, media, fuerte, muy fuerte)
- **Modo claro/oscuro**: Toggle entre temas claro, oscuro y automático (respeta `prefers-color-scheme`)
- **Historial cifrado**: Guarda el historial en Supabase con cifrado AES-GCM (solo tú puedes verlo)
- **Autenticación real**: Login con Supabase (usuario administrador único)
- **Responsive**: Interfaz optimizada para desktop, tablet y mobile
- **Copiar al portapapeles**: Copia con un click y feedback visual

---

## Guía de uso

### Generar contraseña

1. Selecciona el modo **"Contraseña"**
2. Ajusta la longitud (8-128 caracteres)
3. Elige los conjuntos de caracteres: minúsculas, mayúsculas, números, símbolos
4. (Opcional) Ingresa una **clave base** para personalizar el inicio
5. Haz click en **"Generar"** para crear y guardar en historial
6. Haz click en **"Copiar"** para copiar al portapapeles

### Generar frase

1. Selecciona el modo **"Frase"**
2. Ajusta la cantidad de palabras (2-20)
3. (Opcional) Activa "Empezar palabras con mayúscula"
4. Elige idioma: Español o English
5. Haz click en **"Generar"** para crear y guardar en historial
6. Las palabras se separan con guiones automáticamente

### Gestionar historial

- **Ver**: Haz click en el ícono de ojo para revelar/ocultar valores
- **Copiar**: Haz click en el ícono de copiar para copiar una entrada
- **Eliminar individual**: Haz click en el ícono de papelera (requiere confirmación)
- **Limpiar todo**: Botón "Limpiar" (requiere confirmación de seguridad)
- El historial persiste en Supabase (cifrado) entre sesiones

### Tema

- Haz click en el ícono de tema (sol/luna/monitor) en la esquina superior derecha
- Cicla entre: Sistema → Oscuro → Claro → Sistema

### Logout

- Haz click en el ícono de logout (flecha) en la esquina superior derecha
- Se eliminan los datos de sesión (clave de descifrado, token)

---

## Instalación y desarrollo local

### Requisitos

- Node.js 16+ y npm
- Cuenta de Supabase (gratuita en [supabase.com](https://supabase.com))

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/TOB1EH/Password-Generator.git
   cd Password-Generator
   ```

2. **Instalar dependencias**
   ```bash
   npm install
   ```

3. **Configurar variables de entorno**
   - Copia `.env.example` a `.env.local` (si existe)
   - O crea `.env.local` con:
   ```
   VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
   VITE_SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```
   - Obtén tus credenciales de Supabase en: Settings → API → Project URL y anon key

4. **Ejecutar en desarrollo**
   ```bash
   npm run dev
   ```
   - Abre `http://localhost:5173` en tu navegador

5. **Build para producción**
   ```bash
   npm run build
   ```
   - Los artefactos se generan en `dist/`

---

## Configuración de Supabase

### Setup inicial

1. Crea un proyecto en [supabase.com](https://supabase.com)
2. Obtén `Project URL` y `Anon Key` de Settings → API
3. Ejecuta las queries SQL en SQL Editor:
   - Lee `supabase_schema.sql` para crear tabla y políticas RLS
4. Crea usuario administrador:
   - Authentication → Add user
   - Email: tu correo
   - Password: contraseña fuerte
5. Verifica que RLS esté habilitada en la tabla `password_history`

### Notas de seguridad

- **Cifrado simétrico**: Las contraseñas se cifran con AES-GCM en el cliente antes de enviarse a Supabase
- **Clave derivada**: La clave de cifrado se deriva de tu contraseña Supabase con PBKDF2 (sin enviar)
- **Row Level Security (RLS)**: Cada usuario solo ve/modifica sus propias contraseñas
- **Session Storage**: La clave se guarda en `sessionStorage` (se borra al cerrar la pestaña)
- **Anon Key pública**: Es seguro exponerla; RLS protege los datos

---

## Stack tecnológico

- **Frontend**: Vue 3 + Vite
- **Backend**: Supabase (PostgreSQL + Auth + RLS)
- **Cifrado**: Web Crypto API (AES-GCM + PBKDF2)
- **Iconos**: lucide-vue-next
- **Estilos**: CSS scoped (sin frameworks)
- **Deploy**: GitHub Pages + GitHub Actions

---

## Estructura de directorios

```
Password-Generator/
├── src/
│   ├── App.vue              # Componente raíz
│   ├── main.js              # Entry point
│   ├── views/
│   │   ├── LoginView.vue    # Pantalla de login
│   │   └── GeneratorView.vue # Pantalla principal del generador
│   ├── components/
│   │   └── ConfirmDialog.vue # Modal de confirmación reutilizable
│   ├── lib/
│   │   ├── supabase.js      # Cliente Supabase
│   │   ├── crypto.js        # Funciones de cifrado AES-GCM
│   │   ├── password.js      # Generador de contraseñas
│   │   └── passphrase.js    # Generador de frases
│   └── router/
│       └── index.js         # Vue Router (hash history para Pages)
├── dist/                     # Build output (generado)
├── .github/
│   └── workflows/
│       └── deploy.yml       # GitHub Actions para Pages
├── vite.config.js           # Configuración Vite
├── package.json             # Dependencias npm
├── README.md                # Este archivo
├── SUPABASE_SETUP.md        # Guía de configuración Supabase
├── fases-passwordgenerator.md # Plan de fases (desarrollo)
└── supabase_schema.sql      # SQL para crear tabla y RLS
```

---

## Comandos npm

```bash
npm install      # Instalar dependencias
npm run dev      # Ejecutar servidor de desarrollo
npm run build    # Build para producción
npm run preview  # Previsualizar build localmente
npm run lint     # Linter (si está configurado)
```

---

## Notas de desarrollo

### Generación criptográfica
- Usa `crypto.getRandomValues()` (no `Math.random()`)
- Soporta diccionarios español e inglés
- Indicador de entropía basado en longitud y charset size

### Persistencia
- **Local**: tema e historial abierto/cerrado en `localStorage`
- **Remoto**: historial completo (cifrado) en Supabase
- **Sesión**: clave de descifrado temporal en `sessionStorage`

### Limitaciones conocidas
- Historial limitado a 50 entradas por sesión
- Longitud de contraseña: 8-128 caracteres
- Frases: 2-20 palabras

---

## Contribución

Este es un proyecto personal (usuario administrador único). Para sugerencias o bugs, abre un [issue en GitHub](https://github.com/TOB1EH/Password-Generator/issues).

---

## Licencia

Proyecto de código abierto bajo licencia MIT. Úsalo libremente para fines educativos y personales.

---

## Créditos

- Desarrollado por **Tobias Funes**
- Herramientas: [OpenCode](https://opencode.ai) y [Plannotator](https://plannotator.ai)

---

## Links útiles

- **GitHub**: https://github.com/TOB1EH/Password-Generator
- **Supabase Docs**: https://supabase.com/docs
- **Vue 3**: https://vuejs.org
- **Vite**: https://vitejs.dev
- **lucide-vue-next**: https://lucide.dev

---

**¿Preguntas?** Revisa [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) para configuración detallada de Supabase.
