# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [0.0.2] - 2026-10-12

### Añadido
- **Banner 3D «SUSU»** al iniciar, con degradado ANSI 256 (morado → cian),
  colores definidos en variables y versión leída dinámicamente. Pantalla limpia (`clear`)
  y banner compacto en terminales estrechas.
- **Selector de idioma Español/English** como primer paso; se guarda en
  `~/.config/susu/lang` y se puede forzar con `--lang es|en`. Todos los textos,
  menús, errores y confirmaciones están traducidos (i18n con `t()`).
- **Menú principal de 4 opciones**: 1) Instalar · 2) Actualizar · 3) Borrar · 4) Salir,
  mostrando la versión instalada y la última disponible.
- **Opción Borrar (restaurar Termux)**: confirmación explícita escribiendo `si`/`yes`,
  backup rápido opcional, eliminación de configs instaladas y estado, restauración
  del shell por defecto (`chsh -s bash`) y desinstalación de paquetes.
  Nunca toca claves privadas de `~/.ssh` ni `known_hosts`.
- Comparación **SemVer real** (numérica por segmentos) en la opción Actualizar.

### Cambiado
- `uninstall.sh` ahora replica exactamente la opción 3 del menú.
- Lectura de respuestas vía `/dev/tty` para que el menú funcione con `curl | bash`.

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

[0.0.2]: https://github.com/jephersonRD/susu/releases/tag/v0.0.2
[0.0.1]: https://github.com/jephersonRD/susu/releases/tag/v0.0.1
