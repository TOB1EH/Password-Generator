# Backup de Base de Datos - Password Generator

Este documento explica cómo hacer backups de tu base de datos Supabase sin plan premium.

## Inicio Rápido

### 1. Configurar credenciales

```bash
# Copia el archivo de ejemplo
cp .env.example .env.local

# Edita .env.local con tus credenciales Supabase
nano .env.local
```

### 2. Obtener credenciales Supabase

1. Ve a **Supabase Dashboard** → Tu proyecto
2. **Settings** → **API**
   - Copia `Project URL` → `VITE_SUPABASE_URL`
   - Copia `anon key` → `VITE_SUPABASE_ANON_KEY`
3. **Settings** → **Database**
   - Copia `Password` → `SUPABASE_DB_PASSWORD`

### 3. Ejecutar backup

**Opción A: Con npm**
```bash
npm run backup
```

**Opción B: Con bash directo**
```bash
bash backup.sh
```

El script te pedirá la contraseña de la BD si no está configurada.

---

## Qué hace el script

1. Verifica que `.env.local` existe
2. Carga las variables de entorno
3. Construye la URL de conexión a Supabase
4. Ejecuta `pg_dump` para exportar la BD
5. Comprime el backup con `gzip`
6. Guarda en `backups/password_generator_YYYYMMDD_HHMMSS.sql.gz`
7. Limpia automáticamente, manteniendo solo los últimos 10 backups

---

## Requisitos

### pg_dump instalado

El script requiere `pg_dump` (PostgreSQL client tools). Instálalo según tu sistema:

**Ubuntu/Debian**
```bash
sudo apt-get install postgresql-client
```

**macOS**
```bash
brew install postgresql
```

**Windows**
- Descarga PostgreSQL desde https://www.postgresql.org/download/
- O instala solo "Command Line Tools"

**Alternativa: Docker**
Si tienes Docker, el script lo usará automáticamente si `pg_dump` no está disponible.

---

## Restaurar desde Backup

Si necesitas restaurar la base de datos desde un backup:

### Paso 1: Obtener la URL de conexión

```bash
# Lee .env.local
cat .env.local
```

### Paso 2: Descomprimir el backup

```bash
gunzip backups/password_generator_YYYYMMDD_HHMMSS.sql.gz
```

### Paso 3: Restaurar la BD

```bash
# Reemplaza con tu URL real
psql "postgresql://postgres.PROJECT_ID:PASSWORD@PROJECT_ID.supabase.co:5432/postgres" < backups/password_generator_YYYYMMDD_HHMMSS.sql
```

**Advertencia:** La restauración sobrescribirá completamente la base de datos actual. El proyecto será inaccesible durante el proceso.

---

## Automatizar Backups Periódicos

### Linux/macOS (usando cron)

```bash
# Editar crontab
crontab -e

# Agregar una línea para backup diario a las 2 AM
0 2 * * * cd /ruta/a/password_generator && bash backup.sh
```

### Windows (usando Scheduled Tasks)

1. Abre "Task Scheduler"
2. Crear tarea básica
3. Nombre: "Password Generator Daily Backup"
4. Trigger: Diariamente a las 2 AM
5. Action: Ejecutar programa
   - Program: `C:\Program Files\nodejs\node.exe` (o tu ruta de node)
   - Arguments: `-c "npm run backup"` en la carpeta del proyecto

---

## Almacenar Backups de Forma Segura

### Opciones recomendadas

1. **Dropbox/Google Drive**
   ```bash
   # Copiar backups a carpeta sincronizada
   cp backups/*.sql.gz ~/Dropbox/password-generator-backups/
   ```

2. **GitHub (repositorio privado)**
   ```bash
   # Crear rama para backups
   git checkout --orphan backups
   git add backups/
   git commit -m "backup: $(date +%Y%m%d_%H%M%S)"
   git push -u origin backups
   ```

3. **AWS S3 (opción paga pero barata)**
   ```bash
   # Instalar AWS CLI
   pip install awscli
   
   # Configurar credenciales
   aws configure
   
   # Subir backup
   aws s3 cp backups/password_generator_*.sql.gz s3://tu-bucket/password-generator/
   ```

---

## Seguridad

### Proteger archivos .env.local

- **Nunca commitear** `.env.local` (está en `.gitignore`)
- **Nunca compartir** credenciales en código, issues, o PR
- **Usar `.env.local`** solo localmente para desarrollo
- **En producción**, usar variables de entorno del servidor

### Backup encriptado

El backup en `.sql.gz` contiene:
- Estructura de tablas
- Datos (contraseñas **cifradas en AES-GCM**)
- Políticas RLS

Aunque alguien acceda al backup, no puede ver las contraseñas sin la clave de descifrado (derivada de la contraseña Supabase del usuario).

---

## Troubleshooting

### Error: "pg_dump: command not found"

Instala PostgreSQL client tools (ver sección Requisitos arriba).

### Error: "connection refused"

Verifica que:
1. VITE_SUPABASE_URL es correcto (no tiene espacios)
2. SUPABASE_DB_PASSWORD es correcto
3. Tu proyecto Supabase está activo

### Error: "FATAL: password authentication failed"

La contraseña de la BD es incorrecta. Obtén la correcta de:
- Supabase Dashboard → Settings → Database → Password (botón "Reset")

### El backup está muy grande

Los backups pueden ser grandes si tienes mucho histórico. Opciones:
- Eliminar entradas antiguas del historial en la app
- Comprimir backups viejos adicionales
- Usar S3 para almacenamiento long-term

---

## Información Adicional

- **Documentación Supabase Backups**: https://supabase.com/docs/guides/platform/backups
- **PostgreSQL pg_dump**: https://www.postgresql.org/docs/current/app-pgdump.html
- **SQL Restore**: https://www.postgresql.org/docs/current/app-psql.html

---

## Preguntas?

Si tienes dudas sobre backups, abre un issue en GitHub:
https://github.com/TOB1EH/Password-Generator/issues
