#!/bin/bash

# Password Generator - Backup Script (Docker)
# Usa Docker con PostgreSQL para hacer dump de la BD Supabase
# Uso: bash backup.sh o npm run backup

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${YELLOW}Password Generator - Backup Script${NC}"
echo "======================================"

# Verificar Docker
if ! command -v docker &> /dev/null; then
  echo -e "${RED}Error: Docker no esta instalado${NC}"
  exit 1
fi

if ! docker info --format '{{.ServerVersion}}' &>/dev/null; then
  echo -e "${RED}Error: Docker daemon no esta corriendo${NC}"
  echo "Ejecuta: sudo systemctl start docker"
  exit 1
fi

echo -e "${GREEN}Docker $GREEN$DOCKER_VERSION${NC} detectado"

# Cargar .env.local
if [ ! -f .env.local ]; then
  echo -e "${RED}Error: .env.local no encontrado${NC}"
  echo "Copia .env.example a .env.local y completa con tus credenciales"
  exit 1
fi

# Extraer variables del .env.local
VITE_SUPABASE_URL=$(grep '^VITE_SUPABASE_URL=' .env.local | cut -d'=' -f2- | tr -d "'\"")
SUPABASE_DB_PASSWORD=$(grep '^SUPABASE_DB_PASSWORD=' .env.local | cut -d'=' -f2- | tr -d "'\"")

if [ -z "$VITE_SUPABASE_URL" ]; then
  echo -e "${RED}Error: VITE_SUPABASE_URL no configurado en .env.local${NC}"
  exit 1
fi

# Extraer PROJECT_REF de la URL
# Soporta: https://PROJECT_ID.supabase.co o postgresql://...db.PROJECT_ID.supabase.co
if echo "$VITE_SUPABASE_URL" | grep -q 'postgresql://'; then
  PROJECT_REF=$(echo "$VITE_SUPABASE_URL" | sed 's/.*db\.//; s/\.supabase.*//')
else
  PROJECT_REF=$(echo "$VITE_SUPABASE_URL" | sed 's|https://||' | cut -d. -f1)
fi

if [ -z "$PROJECT_REF" ]; then
  echo -e "${RED}Error: No se pudo extraer PROJECT_REF de VITE_SUPABASE_URL${NC}"
  exit 1
fi

# Pedir password si no esta en .env
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
  echo -e "${YELLOW}Ingresa la password de la BD Supabase:${NC}"
  read -s SUPABASE_DB_PASSWORD
  echo ""
fi

# Crear directorio backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/password_generator_${TIMESTAMP}.sql"
BACKUP_FILE_COMPRESSED="${BACKUP_FILE}.gz"

# Construir connection string
DB_HOST="db.${PROJECT_REF}.supabase.co"
DB_USER="postgres.${PROJECT_REF}"
DB_NAME="postgres"
CONN_STRING="postgresql://${DB_USER}:${SUPABASE_DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME}"

echo ""
echo -e "${BLUE}Conectando a Supabase BD...${NC}"
echo -e "Host: ${DB_HOST}"
echo -e "Base de datos: ${DB_NAME}"
echo ""

# Docker run: postgres:alpine con IPv4 forzado
echo -e "${YELLOW}Descargando imagen postgres:alpine (si no esta en cache)...${NC}"
docker pull postgres:alpine --quiet 2>&1

echo -e "${YELLOW}Ejecutando pg_dump via Docker...${NC}"
echo ""

# Resolver IP IPv4 del hostname
IPV4=$(dig +short "$DB_HOST" A 2>/dev/null | head -1)
if [ -z "$IPV4" ]; then
  # Si dig no funciona, intentar getent
  IPV4=$(getent ahosts "$DB_HOST" 2>/dev/null | grep -v ':' | head -1 | awk '{print $1}')
fi

if [ -n "$IPV4" ]; then
  echo -e "${BLUE}IPv4 resuelta: ${IPV4}${NC}"
  echo -e "${BLUE}Usando conexion directa IPv4${NC}"
  echo ""

  DOCKER_EXIT_CODE=0
  DOCKER_OUTPUT=$(docker run --rm \
    -e PGPASSWORD="${SUPABASE_DB_PASSWORD}" \
    --add-host="${DB_HOST}:${IPV4}" \
    postgres:alpine \
    pg_dump \
      -h "$DB_HOST" \
      -U "$DB_USER" \
      -d "$DB_NAME" \
      --no-owner \
      --no-acl \
      --verbose 2>&1) || DOCKER_EXIT_CODE=$?
else
  # Fallback: usar IP directamente con sslmode=require
  echo -e "${YELLOW}No se pudo resolver IPv4, intentando con IPs conocidas...${NC}"
  for TRY_IP in "104.18.38.10" "104.18.39.10" "172.64.149.246"; do
    echo -e "${BLUE}Intentando con IP: ${TRY_IP}...${NC}"
    DOCKER_EXIT_CODE=0
    DOCKER_OUTPUT=$(docker run --rm \
      -e PGPASSWORD="${SUPABASE_DB_PASSWORD}" \
      postgres:alpine \
      pg_dump \
        -h "$TRY_IP" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --no-owner \
        --no-acl \
        --verbose 2>&1) || DOCKER_EXIT_CODE=$?

    if [ $DOCKER_EXIT_CODE -eq 0 ]; then
      echo -e "${GREEN}Conexion exitosa con IP: ${TRY_IP}${NC}"
      break
    fi
  done
fi

if [ $DOCKER_EXIT_CODE -ne 0 ]; then
  echo -e "${RED}Error al conectar via Docker:${NC}"
  echo "$DOCKER_OUTPUT"
  echo ""
  echo -e "${YELLOW}Posibles causas:${NC}"
  echo "  1. Tu IP no esta permitida en Supabase (Network Restrictions)"
  echo "  2. La password es incorrecta"
  echo "  3. Problema temporal de red"
  echo ""
  echo -e "${YELLOW}Para verificar conectividad directamente:${NC}"
  echo -e "  ${GREEN}docker run --rm postgres:alpine pg_isready -h ${DB_HOST} -U ${DB_USER}${NC}"
  exit 1
fi

# Guardar el dump en archivo
echo "$DOCKER_OUTPUT" > "$BACKUP_FILE"

# Verificar que el archivo no este vacio
if [ ! -s "$BACKUP_FILE" ]; then
  echo -e "${RED}Error: El backup generado esta vacio${NC}"
  exit 1
fi

# Obtener tamano y numero de tablas
BACKUP_SIZE=$(wc -l < "$BACKUP_FILE")
echo -e "${GREEN}Backup SQL generado: ${BACKUP_SIZE} lineas${NC}"

# Comprimir
echo -e "${YELLOW}Comprimiendo con gzip...${NC}"
gzip -f "$BACKUP_FILE"

# Mostrar resultado final
FINAL_SIZE=$(du -h "$BACKUP_FILE_COMPRESSED" | cut -f1)
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Backup completado exitosamente${NC}"
echo -e "${GREEN}Archivo: ${BACKUP_FILE_COMPRESSED}${NC}"
echo -e "${GREEN}Tamano: ${FINAL_SIZE}${NC}"
echo -e "${GREEN}======================================${NC}"

# Limpiar backups antiguos (mantener ultimos 10)
cd "$BACKUP_DIR"
ls -t password_generator_*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
echo -e "${YELLOW}Backups antiguos limpiados (max 10 guardados)${NC}"

echo -e "${BLUE}Puedes encontrar todos los backups en: ${BACKUP_DIR}/${NC}"
echo ""
