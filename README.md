# Scripts de Backup de Grafana

## Descripción

Este script te permite realizar backups completos de tu instalación de Grafana antes de realizar upgrades.

## Contenido

- **grafana_backup.sh**: Script para crear backup completo de Grafana

## Características del Backup

El script de backup incluye:

✅ Base de datos SQLite de Grafana (`grafana.db`)

✅ Archivos de configuración (`/etc/grafana`)

✅ Plugins instalados

✅ Dashboards provisioned

✅ Datasources provisioned

✅ Alerting provisioned

✅ Notifiers provisioned

✅ Logs recientes (últimos 7 días)

✅ Configuración del servicio systemd

✅ Información del sistema y versión

✅ Checksums para verificación de integridad

✅ Compresión automática del backup


## Uso

### Realizar un Backup

```bash
# Dar permisos de ejecución (solo la primera vez)
sudo chmod +x grafana_backup.sh

# Ejecutar el backup
sudo ./grafana_backup.sh
```

El backup se guardará en `/backup/grafana_backup_YYYYMMDD_HHMMSS.tar.gz`

## Requisitos

- Sistema Linux (Ubuntu/Debian/CentOS/RHEL)
- Grafana instalado
- Acceso root o sudo
- Espacio suficiente en disco para el backup

## Rutas por Defecto

El script asume las siguientes rutas estándar:

- Datos de Grafana: `/var/lib/grafana`
- Configuración: `/etc/grafana`
- Logs: `/var/log/grafana`
- Backups: `/backup/`

Si tu instalación usa rutas diferentes, edita las variables al inicio del script:

```bash
GRAFANA_HOME="/var/lib/grafana"
GRAFANA_CONFIG="/etc/grafana"
GRAFANA_LOGS="/var/log/grafana"
```

## Proceso de Backup

1. Verifica permisos de root
2. Crea directorio de backup con timestamp
3. Guarda la versión actual de Grafana
4. Copia la base de datos
5. Copia archivos de configuración
6. Copia plugins
7. Copia dashboards y datasources provisioned
8. Copia logs recientes
9. Guarda información del sistema
10. Genera checksums para verificación
11. Comprime todo en un archivo .tar.gz



## Ejemplo de Flujo de Trabajo Completo

```bash
# 1. Hacer backup antes del upgrade
sudo ./grafana_backup.sh

# Output:
# [2024-01-28 12:00:00] Backup completado exitosamente
# Ubicación: /backup/grafana_backup_20240128_120000.tar.gz
# Tamaño: 45M

```

## Verificación de Integridad

Puedes verificar manualmente la integridad del backup:

```bash
# Extraer el backup
tar -xzf /backup/grafana_backup_20240128_120000.tar.gz -C /tmp

# Verificar checksums
cd /tmp/grafana_backup_20240128_120000
sha256sum -c checksums.sha256
```

## Gestión de Backups

### Listar backups existentes

```bash
ls -lh /backup/grafana_backup_*.tar.gz
```

### Eliminar backups antiguos (ejemplo: más de 30 días)

```bash
find /backup -name "grafana_backup_*.tar.gz" -mtime +30 -delete
```

## Solución de Problemas

### El script no encuentra Grafana

Verifica que Grafana está instalado:
```bash
which grafana-server
systemctl status grafana-server
```

### Error de permisos

Asegúrate de ejecutar con sudo:
```bash
sudo ./grafana_backup.sh
```

### No hay espacio en disco

Verifica el espacio disponible:
```bash
df -h /backup
```

## Notas Importantes

⚠️ **IMPORTANTE**: Este script está diseñados para instalaciones estándar de Grafana con base de datos SQLite. Si usas PostgreSQL, MySQL u otro backend, necesitarás modificar la sección de backup de la base de datos.

⚠️ **SEGURIDAD**: Los backups pueden contener información sensible (API keys, contraseñas, tokens). Asegúrate de proteger los archivos de backup y limitar el acceso.

⚠️ **PRUEBAS**: Siempre prueba el proceso de restauración en un ambiente de prueba antes de confiar en él para producción.

## Backup de Bases de Datos Externas

Si usas PostgreSQL o MySQL:

### PostgreSQL
```bash
pg_dump grafana > grafana_db_backup.sql
```

### MySQL
```bash
mysqldump -u grafana -p grafana > grafana_db_backup.sql
```

## Soporte

Para más información sobre Grafana:
- Documentación oficial: https://grafana.com/docs/
- Guía de upgrade: https://grafana.com/docs/grafana/latest/setup-grafana/upgrade-grafana/

## Licencia

Estos scripts son de código abierto y pueden ser modificados según tus necesidades.
