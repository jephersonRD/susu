# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [0.0.1] - 2026-10-12

### Añadido
- Instalador de una línea `install.sh` con:
  - Detección de la última versión vía API de GitHub (grep/sed, sin jq).
  - Descarga con barra de progreso real (porcentaje, MB y velocidad).
  - Instalación idempotente de paquetes (zsh, htop, yazi, fastfetch, openssh).
  - Backup automático de configuraciones previas.
- Configuraciones incluidas:
  - `config/zsh/.zshrc` — prompt Starship, plugins, saludo animado.
  - `config/fastfetch/` — ASCII pastel + módulos del sistema.
  - `config/htop/htoprc` — layout de dos columnas.
  - `config/yazi/yazi.toml` — preview, orden natural, directorios primero.
  - `config/ssh/config` — plantilla segura sin claves.
- `uninstall.sh` para restaurar backups.
- Workflow de GitHub Actions para publicar releases con `.tar.gz` al crear tags.
- Licencia MIT, README profesional y carpeta `assets/` para imágenes y vídeos.

[0.0.1]: https://github.com/jephersonRD/susu/releases/tag/v0.0.1
