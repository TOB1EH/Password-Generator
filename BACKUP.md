# Backup de Base de Datos - Password Generator

Sistema de backup confiable para tu base de datos Supabase usando REST API (sin IPv6).

## Inicio Rápido

### 1. Configurar credenciales

```bash
# Edita .env.local
nano .env.local
```

Agrega o verifica estas líneas:

```bash
VITE_SUPABASE_URL=https://eqvcitdiyfmukaiwegrs.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_AUTH_EMAIL=tu_email@ejemplo.com
SUPABASE_AUTH_PASSWORD=tu_password_login
```

**Importante**: 
- `SUPABASE_AUTH_EMAIL` y `SUPABASE_AUTH_PASSWORD` son los datos que usas en la pantalla de **Login** de la app
- NO son la contraseña de la base de datos

### 2. Ejecutar backup

```bash
npm run backup
```

El script:
1. Te autentica en Supabase como usuario
2. Descarga todo el historial de contraseñas
3. Genera un archivo SQL.gz comprimido
4. Lo guarda en `backups/password_generator_YYYYMMDD_HHMMSS.sql.gz`

---

## Cómo Funciona

El backup usa la **REST API de Supabase** (HTTPS), no la conexión PostgreSQL directa. Esto:

- ✅ **Funciona sin IPv6** (solo requiere HTTPS)
- ✅ **Respeta RLS** (Row Level Security) - solo accede a tus datos
- ✅ **No necesita herramientas externas** (solo Node.js)
- ✅ **Datos cifrados** en el backup (AES-GCM)
- ✅ **Portable** entre máquinas

---

## Restaurar desde Backup

### Paso Previo: Descomprimir el backup

```bash
# Encuentra el archivo .sql.gz más reciente
ls -lt backups/*.sql.gz | head -1

# Descomprime
gunzip backups/password_generator_YYYYMMDD_HHMMSS.sql.gz
# Resultado: password_generator_YYYYMMDD_HHMMSS.sql
```

### Opción 1: Restaurar en Nuevo Proyecto Supabase

**Caso de uso**: Migrar a otro proyecto Supabase, disaster recovery.

**Paso 1**: Crea nuevo proyecto en Supabase
- Ve a [supabase.com](https://supabase.com)
- Click "New Project"
- Esperar 2-3 minutos a que se cree

**Paso 2**: Prepara la estructura (SQL Editor)
- Copia contenido completo de `supabase_schema.sql`
- Pega en SQL Editor del nuevo proyecto
- Ejecuta completamente

**Paso 3**: Importa datos del backup
```bash
# Obtén connection string del nuevo proyecto
# Settings → Database → Connection string (URI)

psql "postgresql://postgres.PROJECT_ID:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres" < password_generator_YYYYMMDD_HHMMSS.sql
```

**Si no tienes psql**: Copia el `.sql` directamente en SQL Editor y ejecuta.

### Opción 2: Restaurar en Proyecto Existente

**Caso de uso**: Recuperar datos borrados, combinar backups.

**Advertencia**: Haz backup antes de esto.

**Método 1 - SQL Editor** (más fácil):
1. Abre archivo `.sql` en editor de texto
2. Ve a Supabase Dashboard → SQL Editor
3. Copia/pega contenido
4. Click "RUN"

**Método 2 - psql**:
```bash
psql "postgresql://postgres.PROJECT_ID:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres" < password_generator_YYYYMMDD_HHMMSS.sql
```

### Opción 3: Restaurar Parcialmente

Los archivos `.sql` son texto. Puedes editarlos:

```bash
# Combinar dos backups
cat backup1.sql backup2.sql > combined.sql

# Editar para traer solo ciertos registros
nano combined.sql

# Restaurar
psql "CONNECTION_STRING" < combined.sql
```

### Verificar Restauración

```bash
# Recarga la app - deberías ver el historial

# O verifica con SQL:
SELECT COUNT(*) FROM password_history;
```

---

## Troubleshooting Restauración

### Error: "relation password_history does not exist"

Causa: No ejecutaste `supabase_schema.sql`

Solución:
1. SQL Editor → Copia `supabase_schema.sql` completo
2. Ejecuta en Supabase
3. Luego importa el backup

### Error: "permission denied"

Solución: Verifica que estés autenticado como usuario correcto

### Error: "psql: command not found"

Solución: 
```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# macOS
brew install postgresql
```

O usa SQL Editor en lugar de psql

---

## Automatizar Backups

### Linux/macOS (cron)

```bash
# Editar crontab
crontab -e

# Agregar línea (backup diario a las 2 AM)
0 2 * * * cd /ruta/proyecto && npm run backup
```

### Windows (Scheduled Task)

1. Abre "Task Scheduler"
2. Crear tarea básica
3. Nombre: "Password Generator Backup"
4. Trigger: Diariamente 02:00 AM
5. Action: 
   - Program: `C:\Program Files\nodejs\node.exe`
   - Arguments: `/path/to/backup.mjs`
   - Start in: `C:\path\to\project`

---

## Almacenar Backups en la Nube

### Dropbox/Google Drive

```bash
# Copiar backups automáticamente
cp backups/*.sql.gz ~/Dropbox/Password-Generator-Backups/
```

O crear script que lo haga automáticamente:
```bash
#!/bin/bash
npm run backup
cp backups/*.sql.gz ~/Dropbox/Password-Generator-Backups/
```

### GitHub (repositorio privado)

```bash
# Crear rama separada para backups
git checkout --orphan backups-storage
git rm -rf .
cp ../backups/password_generator_*.sql.gz .
git add *.sql.gz
git commit -m "backup: $(date)"
git push -u origin backups-storage
```

### AWS S3

```bash
# Instalar AWS CLI
pip install awscli

# Configurar
aws configure

# Subir
aws s3 cp backups/password_generator_*.sql.gz s3://tu-bucket/password-generator/
```

---

## Estructura del Backup

El archivo `.sql.gz` contiene:

```sql
-- Password Generator - Backup
-- Fecha: 15/05/2026 21:38
-- Usuario: tobiasfunes@hotmail.com.ar

BEGIN;

INSERT INTO password_history ("id", "user_id", "value", "type", "created_at") 
  VALUES ('uuid-123', 'cc773174-3e35-4996-b1db-412c04319b2c', 'ENCRYPTED_DATA', 'password', '2026-05-15T21:30:00');

COMMIT;
```

**Notas**:
- El campo `value` contiene la contraseña **cifrada en AES-GCM**
- Sin la clave de descifrado (derivada de tu password Supabase), los datos no son útiles
- El archivo es 100% texto, fácil de procesar

---

## Seguridad

### Credenciales en .env.local

- ✅ Está en `.gitignore` (nunca se commitea)
- ✅ Permanece solo en tu máquina
- ⚠️ No la compartir ni publicar

### Backup Encriptado

- ✅ Datos cifrados en AES-GCM en el backup
- ✅ Sin clave de descifrado, el backup es ilegible
- ✅ La clave se genera con tu password Supabase
- ✅ Seguro almacenar en la nube

### RLS Protección

- ✅ Solo tu usuario puede acceder a tus datos
- ✅ Imposible acceder sin tus credenciales
- ✅ La app valida permisos en Supabase

---

## Troubleshooting

### Error: "Invalid login credentials"

```
Error de autenticacion: Invalid login credentials
```

- Verifica que `SUPABASE_AUTH_EMAIL` y `SUPABASE_AUTH_PASSWORD` sean correctos
- Son los datos de **Login** de la app, no la BD

### Error: "Unauthorized"

- El usuario no tiene acceso a la tabla `password_history`
- Verifica RLS en Supabase Dashboard

### Backup muy pequeño o vacío

- La tabla puede estar vacía
- O solo tienes 1 registro (normal)
- Usa la app para generar más contraseñas

### "Connection refused" o timeout

- Solo sucede con `pg_dump` (método legacy)
- El método REST API (nuevo) debería funcionar siempre

---

## Scripts Disponibles

```bash
npm run backup          # Backup via REST API (recomendado)
npm run backup:legacy   # Backup via pg_dump/Docker (requiere IPv6)
npm run build           # Build para producción
npm run dev             # Desarrollo local
```

---

## Información Adicional

- **Documentación Supabase**: https://supabase.com/docs/guides/platform/backups
- **REST API Docs**: https://supabase.com/docs/reference/javascript/select
- **Seguridad**: https://supabase.com/docs/guides/platform/security-overview

---

## Preguntas?

Abre un issue en GitHub:
https://github.com/TOB1EH/Password-Generator/issues
