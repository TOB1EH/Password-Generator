#!/bin/bash

# Script de Backup Automático para Password Generator
# Crea un dump encriptado de la base de datos Supabase
# Uso: bash backup.sh o npm run backup

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Password Generator - Backup Script${NC}"
echo "======================================"

# 1. Verificar que .env.local existe
if [ ! -f .env.local ]; then
  echo -e "${RED}Error: .env.local no encontrado${NC}"
  echo "Copia .env.example a .env.local y completa con tus credenciales Supabase"
  exit 1
fi

# 2. Cargar variables de entorno
export $(cat .env.local | grep -v '^#' | xargs)

# 3. Verificar que VITE_SUPABASE_URL está configurado
if [ -z "$VITE_SUPABASE_URL" ]; then
  echo -e "${RED}Error: VITE_SUPABASE_URL no configurado en .env.local${NC}"
  exit 1
fi

# 4. Crear directorio de backups si no existe
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"

# 5. Generar nombre del backup con timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/password_generator_${TIMESTAMP}.sql"
BACKUP_FILE_COMPRESSED="${BACKUP_FILE}.gz"

# 6. Construir connection string desde VITE_SUPABASE_URL
# Formato esperado: https://PROJECT_ID.supabase.co
# Convertir a: postgresql://postgres.PROJECT_ID:PASSWORD@PROJECT_ID.supabase.co:5432/postgres

# Extraer PROJECT_ID de la URL
PROJECT_ID=$(echo "$VITE_SUPABASE_URL" | sed 's|https://||' | cut -d. -f1)

# Verificar que se extrajo correctamente
if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}Error: No se pudo extraer PROJECT_ID de VITE_SUPABASE_URL${NC}"
  echo "Asegúrate que VITE_SUPABASE_URL tenga formato: https://PROJECT_ID.supabase.co"
  exit 1
fi

# Pedir contraseña si no está disponible
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
  echo -e "${YELLOW}Ingresa la contraseña de la base de datos Supabase:${NC}"
  read -s SUPABASE_DB_PASSWORD
  if [ -z "$SUPABASE_DB_PASSWORD" ]; then
    echo -e "${RED}Error: Contraseña vacía${NC}"
    exit 1
  fi
fi

# Construir connection string
DB_URL="postgresql://postgres.${PROJECT_ID}:${SUPABASE_DB_PASSWORD}@${PROJECT_ID}.supabase.co:5432/postgres"

# 7. Ejecutar pg_dump
echo -e "${YELLOW}Creando backup de la base de datos...${NC}"

if command -v pg_dump &> /dev/null; then
  # pg_dump disponible localmente
  pg_dump "$DB_URL" > "$BACKUP_FILE"
else
  # Intenta con podman/docker
  echo -e "${YELLOW}pg_dump no encontrado localmente. Intentando con Docker...${NC}"
  docker run --rm postgres:15 pg_dump "$DB_URL" > "$BACKUP_FILE" || {
    echo -e "${RED}Error: pg_dump no disponible. Instala PostgreSQL client tools:${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  macOS: brew install postgresql"
    echo "  Windows: Instala PostgreSQL desde https://www.postgresql.org/download/"
    exit 1
  }
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo -e "${RED}Error: No se pudo crear el backup${NC}"
  exit 1
fi

# 8. Comprimir el backup
echo -e "${YELLOW}Comprimiendo backup...${NC}"
gzip "$BACKUP_FILE"

# 9. Mostrar resultado
BACKUP_SIZE=$(du -h "$BACKUP_FILE_COMPRESSED" | cut -f1)
echo -e "${GREEN}Backup completado exitosamente${NC}"
echo -e "Archivo: ${GREEN}$BACKUP_FILE_COMPRESSED${NC} (${GREEN}${BACKUP_SIZE}${NC})"

# 10. Limpiar archivos antiguos (mantener últimos 10 backups)
echo -e "${YELLOW}Limpiando backups antiguos (guardando últimos 10)...${NC}"
cd "$BACKUP_DIR"
ls -t password_generator_*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm

echo -e "${GREEN}Done!${NC}"
