#!/bin/bash

################################################################################
# Script de Backup de Grafana
# Propósito: Respaldar archivos críticos de Grafana antes de un upgrade
# Uso: ./grafana_backup.sh
################################################################################

set -e  # Terminar si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Configuración
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/grafana_backup_${BACKUP_DATE}"
GRAFANA_HOME="/var/lib/grafana"
GRAFANA_CONFIG="/etc/grafana"
GRAFANA_LOGS="/var/log/grafana"

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

# Crear directorio de backup
print_message "Creando directorio de backup: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

# Verificar que Grafana está instalado
if ! command -v grafana-server &> /dev/null; then
    print_warning "Grafana no parece estar instalado o no está en el PATH"
fi

# Obtener versión actual de Grafana
if command -v grafana-server &> /dev/null; then
    GRAFANA_VERSION=$(grafana-server -v 2>&1 | grep -oP 'Version \K[0-9.]+' || echo "desconocida")
    print_message "Versión actual de Grafana: ${GRAFANA_VERSION}"
    echo "${GRAFANA_VERSION}" > "${BACKUP_DIR}/version.txt"
fi

# Backup de la base de datos de Grafana
print_message "Respaldando base de datos de Grafana..."
if [ -f "${GRAFANA_HOME}/grafana.db" ]; then
    cp -v "${GRAFANA_HOME}/grafana.db" "${BACKUP_DIR}/grafana.db"
    print_message "Base de datos SQLite respaldada"
else
    print_warning "No se encontró grafana.db en ${GRAFANA_HOME}"
fi

# Backup de archivos de configuración
print_message "Respaldando archivos de configuración..."
if [ -d "${GRAFANA_CONFIG}" ]; then
    cp -r "${GRAFANA_CONFIG}" "${BACKUP_DIR}/config"
    print_message "Configuración respaldada desde ${GRAFANA_CONFIG}"
else
    print_warning "No se encontró directorio de configuración ${GRAFANA_CONFIG}"
fi

# Backup de plugins
print_message "Respaldando plugins..."
if [ -d "${GRAFANA_HOME}/plugins" ]; then
    cp -r "${GRAFANA_HOME}/plugins" "${BACKUP_DIR}/plugins"
    print_message "Plugins respaldados"
else
    print_warning "No se encontró directorio de plugins"
fi

# Backup de dashboards (si están almacenados como archivos)
print_message "Respaldando dashboards provisioned..."
if [ -d "/etc/grafana/provisioning/dashboards" ]; then
    cp -r "/etc/grafana/provisioning/dashboards" "${BACKUP_DIR}/provisioned_dashboards"
    print_message "Dashboards provisioned respaldados"
fi

# Backup de datasources provisioned
print_message "Respaldando datasources provisioned..."
if [ -d "/etc/grafana/provisioning/datasources" ]; then
    cp -r "/etc/grafana/provisioning/datasources" "${BACKUP_DIR}/provisioned_datasources"
    print_message "Datasources provisioned respaldados"
fi

# Backup de alerting provisioned
print_message "Respaldando alerting provisioned..."
if [ -d "/etc/grafana/provisioning/alerting" ]; then
    cp -r "/etc/grafana/provisioning/alerting" "${BACKUP_DIR}/provisioned_alerting"
    print_message "Alerting provisioned respaldado"
fi

# Backup de notifiers provisioned
print_message "Respaldando notifiers provisioned..."
if [ -d "/etc/grafana/provisioning/notifiers" ]; then
    cp -r "/etc/grafana/provisioning/notifiers" "${BACKUP_DIR}/provisioned_notifiers"
    print_message "Notifiers provisioned respaldados"
fi

# Backup de logs (últimos archivos)
print_message "Respaldando logs recientes..."
if [ -d "${GRAFANA_LOGS}" ]; then
    mkdir -p "${BACKUP_DIR}/logs"
    find "${GRAFANA_LOGS}" -type f -mtime -7 -exec cp {} "${BACKUP_DIR}/logs/" \;
    print_message "Logs de los últimos 7 días respaldados"
fi

# Backup de servicio systemd
print_message "Respaldando configuración de servicio systemd..."
if [ -f "/etc/systemd/system/grafana-server.service" ]; then
    cp "/etc/systemd/system/grafana-server.service" "${BACKUP_DIR}/grafana-server.service"
elif [ -f "/lib/systemd/system/grafana-server.service" ]; then
    cp "/lib/systemd/system/grafana-server.service" "${BACKUP_DIR}/grafana-server.service"
fi

# Crear archivo de información del sistema
print_message "Guardando información del sistema..."
{
    echo "=== Información del Sistema ==="
    echo "Fecha del backup: ${BACKUP_DATE}"
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)"
    echo "Kernel: $(uname -r)"
    echo ""
    echo "=== Información de Grafana ==="
    echo "Versión: ${GRAFANA_VERSION}"
    systemctl status grafana-server --no-pager 2>/dev/null || echo "Estado del servicio no disponible"
    echo ""
    echo "=== Paquetes instalados relacionados ==="
    if command -v dpkg &> /dev/null; then
        dpkg -l | grep -i grafana 2>/dev/null || echo "No se encontraron paquetes dpkg relacionados con grafana"
    elif command -v rpm &> /dev/null; then
        rpm -qa | grep -i grafana 2>/dev/null || echo "No se encontraron paquetes rpm relacionados con grafana"
    else
        echo "No se pudo determinar el gestor de paquetes"
    fi
} > "${BACKUP_DIR}/system_info.txt"

# Crear checksum de los archivos respaldados
print_message "Generando checksums..."
cd "${BACKUP_DIR}"
find . -type f -exec sha256sum {} \; > checksums.sha256
cd - > /dev/null

# Comprimir el backup
print_message "Comprimiendo backup..."
BACKUP_ARCHIVE="/backup/grafana_backup_${BACKUP_DATE}.tar.gz"
tar -czf "${BACKUP_ARCHIVE}" -C /backup "grafana_backup_${BACKUP_DATE}"

# Calcular tamaño del backup
BACKUP_SIZE=$(du -sh "${BACKUP_ARCHIVE}" | cut -f1)

print_message "=== Backup completado exitosamente ==="
print_message "Ubicación: ${BACKUP_ARCHIVE}"
print_message "Tamaño: ${BACKUP_SIZE}"
print_message "Directorio sin comprimir: ${BACKUP_DIR}"


exit 0
