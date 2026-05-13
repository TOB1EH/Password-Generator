#!/bin/bash

# Script de Backup Automático para Password Generator
# Crea un dump de la base de datos Supabase usando pgAdmin o comando directo
# Uso: bash backup.sh o npm run backup

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 6. Extraer PROJECT_ID de la URL
PROJECT_ID=$(echo "$VITE_SUPABASE_URL" | sed 's|https://||' | cut -d. -f1)

if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}Error: No se pudo extraer PROJECT_ID de VITE_SUPABASE_URL${NC}"
  echo "Asegúrate que VITE_SUPABASE_URL tenga formato: https://PROJECT_ID.supabase.co"
  exit 1
fi

# 7. Pedir contraseña si no está disponible
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
  echo -e "${YELLOW}Ingresa la contraseña de la base de datos Supabase:${NC}"
  read -s SUPABASE_DB_PASSWORD
  if [ -z "$SUPABASE_DB_PASSWORD" ]; then
    echo -e "${RED}Error: Contraseña vacía${NC}"
    exit 1
  fi
fi

# 8. Mostrar instrucciones
echo -e "${BLUE}Creando backup de la base de datos...${NC}"
echo ""
echo -e "${YELLOW}Opción 1: Si tienes pg_dump instalado${NC}"
echo -e "Ejecuta este comando en tu terminal:"
echo ""
echo -e "${GREEN}PGPASSWORD='${SUPABASE_DB_PASSWORD}' pg_dump -h db.${PROJECT_ID}.supabase.co -U postgres.${PROJECT_ID} -d postgres > ${BACKUP_FILE}${NC}"
echo ""
echo -e "${YELLOW}Opción 2: Usar pgAdmin (interfaz gráfica)${NC}"
echo -e "1. Ve a: https://supabase.com/dashboard/project/${PROJECT_ID}/database/pgadmin"
echo -e "2. En el menú izquierdo, haz click en 'Databases' → 'postgres'"
echo -e "3. Click derecho → 'Backup' → Guardar archivo"
echo ""
echo -e "${YELLOW}Opción 3: Descargar backup automático${NC}"
echo -e "1. Ve a: https://supabase.com/dashboard/project/${PROJECT_ID}/database/backups"
echo -e "2. Descarga el backup disponible (requiere plan Pro)"
echo ""

# 9. Intenta con pg_dump si está disponible
if command -v pg_dump &> /dev/null; then
  echo -e "${BLUE}Intentando usar pg_dump...${NC}"
  
  # Usar timeout para evitar cuelgues
  timeout 15 bash -c "PGPASSWORD='${SUPABASE_DB_PASSWORD}' pg_dump -h db.${PROJECT_ID}.supabase.co -U postgres.${PROJECT_ID} -d postgres > '${BACKUP_FILE}'" 2>/dev/null && {
    echo -e "${GREEN}Backup creado exitosamente${NC}"
    
    # Comprimir
    echo -e "${YELLOW}Comprimiendo...${NC}"
    gzip "$BACKUP_FILE"
    
    BACKUP_SIZE=$(du -h "$BACKUP_FILE_COMPRESSED" | cut -f1)
    echo -e "${GREEN}Backup completado: ${BACKUP_FILE_COMPRESSED} (${BACKUP_SIZE})${NC}"
    
    # Limpiar backups antiguos
    cd "$BACKUP_DIR"
    ls -t password_generator_*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm
    
    exit 0
  } || {
    echo -e "${YELLOW}pg_dump no pudo conectar (timeout). Usa las opciones anteriores manualmente.${NC}"
  }
else
  echo -e "${YELLOW}pg_dump no está instalado. Usa pgAdmin o descarga manual (ver opciones arriba).${NC}"
fi

echo ""
echo -e "${RED}Para instalar pg_dump:${NC}"
echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
echo "  macOS: brew install postgresql"
echo "  Windows: Instala PostgreSQL desde https://www.postgresql.org/download/"
echo ""
echo -e "${BLUE}Documentación: https://github.com/TOB1EH/Password-Generator/blob/main/BACKUP.md${NC}"
