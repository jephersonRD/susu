<div align="center">

<!-- Reemplaza con tu banner: sube assets/banner.png -->
<img src="assets/banner.png" alt="susu" width="640"/>

# susu

**Mi personalización completa de Termux con un solo comando.**

[![Versión](https://img.shields.io/github/v/release/jephersonRD/susu?label=versi%C3%B3n&color=blueviolet)](https://github.com/jephersonRD/susu/releases/latest)
[![Licencia](https://img.shields.io/badge/licencia-MIT-green)](LICENSE)
[![Plataforma](https://img.shields.io/badge/plataforma-Termux%20%7C%20Android-black?logo=android&logoColor=white)](https://termux.dev)
[![Instalador](https://img.shields.io/badge/instalador-curl%20%7C%20bash-orange)](install.sh)

</div>

---

## 📖 Descripción

Repositorio con **mi setup completo de Termux**: shell zsh con prompt estilo powerline en tonos morado/azul pastel, saludo de bienvenida animado, fastfetch con arte ASCII, y las herramientas de terminal que uso a diario — todo instalable con **una sola línea** y restaurable con otra.

## ✨ Características

- 🎛 **Menú interactivo** — 1) Instalar · 2) Actualizar · 3) Borrar · 4) Salir.
- 🌐 **Selector de idioma** — Español/English, se recuerda y se cambia con `--lang`.
- 🏷 **Banner 3D «SUSU»** — degradado morado → cian con la versión dinámica.
- 🚀 **Instalación en 1 comando** — detecta versiones, descarga el último release y configura todo.
- 📊 **Progreso real de descarga** — barra con porcentaje, tamaño y velocidad obtenidos del `Content-Length`.
- 🔁 **Idempotente** — ejecútalo las veces que quieras; solo instala lo que falta.
- 💾 **Backups automáticos** — tus configs anteriores se guardan antes de sobrescribir.
- 🧹 **Borrado completo** — la opción 3 deja Termux por defecto (configs + paquetes + shell).
- 🔐 **Sin secretos** — cero claves privadas, tokens o contraseñas en el repo.

## 🕹 Uso

Al ejecutarlo verás el banner y el menú:

```
╭─ susu ─────────────────────────────────╮
│  Instalada: v0.0.1   Disponible: v0.0.2
╰────────────────────────────────────────╯
  1) Instalar
  2) Actualizar
  3) Borrar (restaurar Termux)
  4) Salir
```

- **1 · Instalar** — instala paquetes que falten, hace backup y copia las configs.
- **2 · Actualizar** — compara versiones con SemVer real y solo descarga si hay una nueva.
- **3 · Borrar** — confirmación escribiendo `si`/`yes`, backup opcional y reseteo total
  (nunca toca tus claves SSH privadas).
- La primera vez pregunta el idioma y lo guarda en `~/.config/susu/lang`.
  Cámbialo cuando quieras: `bash install.sh --lang en` (o `es`).

## 📸 Vista previa

<!-- Sube tus capturas a assets/screenshots/ y tu demo a assets/demo.gif -->

<div align="center">
  <img src="assets/screenshots/banner.png" alt="Banner 3D SUSU" width="60%"/>
  <br/><br/>
  <img src="assets/screenshots/preview-1.png" alt="Menú principal e idioma" width="45%"/>
  <img src="assets/screenshots/preview-2.png" alt="fastfetch con arte ASCII" width="45%"/>
  <br/><br/>
  ▶️ [Ver vídeo demo](assets/demo.mp4)
</div>

## ⚡ Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/jephersonRD/susu/main/install.sh | bash
```

Al terminar, **cierra y vuelve a abrir Termux**.

## 🔄 Actualizar

Vuelve a ejecutar el mismo comando. El instalador:

1. Consulta la última versión publicada en GitHub.
2. La compara con la que tienes (`~/.config/susu/version`).
3. Si ya estás al día te avisa y pregunta si quieres reinstalar; si hay una nueva, descarga y aplica.

## 📦 Qué se instala

| Paquete     | Uso                                        |
| ----------- | ------------------------------------------ |
| `zsh`       | Shell principal                            |
| `htop`      | Monitor de procesos                        |
| `yazi`      | Gestor de archivos TUI                     |
| `fastfetch` | Información del sistema con arte ASCII     |
| `openssh`   | Cliente/servidor SSH (`ssh` / `sshd`)      |

Y estas configuraciones se copian a tu `$HOME`:

| Archivo del repo             | Destino                     |
| ---------------------------- | --------------------------- |
| `config/zsh/.zshrc`          | `~/.zshrc`                  |
| `config/fastfetch/*`         | `~/.config/fastfetch/`      |
| `config/htop/htoprc`         | `~/.config/htop/htoprc`     |
| `config/yazi/yazi.toml`      | `~/.config/yazi/yazi.toml`  |
| `config/ssh/config`          | `~/.ssh/config` (modo 600)  |

## 🗂 Estructura del repositorio

```
susu/
├── install.sh                  # Instalador de una línea
├── uninstall.sh                # Restaura el último backup
├── VERSION                     # Versión actual (SemVer)
├── CHANGELOG.md                # Historial de cambios (Keep a Changelog)
├── LICENSE                     # MIT
├── config/
│   ├── zsh/.zshrc
│   ├── fastfetch/config.jsonc + logo.txt
│   ├── htop/htoprc
│   ├── yazi/yazi.toml
│   └── ssh/config              # ⚠ solo plantilla, nunca claves
├── assets/                     # Banner, capturas y vídeos del README
└── ci/                      # renómbralo a .github/workflows/release.yml para activarlo
    └── release.yml             # Publica release + .tar.gz en cada tag
```

## 🗑 Desinstalación

Dos formas equivalentes (la opción 3 del menú hace exactamente lo mismo):

1. Ejecuta el instalador y elige **3) Borrar**.
2. O directamente:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jephersonRD/susu/main/uninstall.sh)
```

Pide confirmación escribiendo **`si`** / **`yes`**, ofrece un backup rápido en
`~/.susu-backup/<fecha>` y después:

- elimina `~/.zshrc`, los configs de fastfetch/htop/yazi, `~/.ssh/config` y `~/.config/susu`;
- restaura el shell por defecto (`chsh -s bash`);
- desinstala los paquetes `zsh`, `htop`, `yazi`, `fastfetch` y `openssh`.

> ⚠️ Tus claves privadas (`~/.ssh/id_*`) y `known_hosts` **nunca** se tocan.

## 🆕 Novedades v0.0.2

- Banner 3D «SUSU» con degradado y versión dinámica.
- Selector de idioma ES/EN (`--lang`) y menú de 4 opciones.
- Opción de borrado completo + desinstalador alineado.
- Comparación SemVer numérica real en Actualizar.

Historial completo en [CHANGELOG.md](CHANGELOG.md).

## 🚢 Publicar una nueva versión (mantenedor)

Este proyecto usa [SemVer](https://semver.org/lang/es/).

```bash
# 1. Actualiza VERSION y CHANGELOG.md
echo "0.0.2" > VERSION

# 2. Commit y tag
git add -A && git commit -m "release: v0.0.2"
git tag v0.0.2
git push origin main --tags
```

El workflow [`release.yml`](ci/release.yml) crea automáticamente el release y adjunta el `.tar.gz`. También puedes hacerlo manual:

```bash
gh release create v0.0.2 -t "susu v0.0.2" --generate-notes
```

## 🤝 Contribuciones

¡Bienvenidas! Abre un *issue* para proponer ideas o reportar errores, o un *pull request* con tu mejora. Reglas básicas:

1. Haz *fork*, crea una rama (`git checkout -b mejora/mi-idea`) y envía el PR.
2. Sigue el estilo del código existente (comentarios, español, `set -euo pipefail`).
3. **Nunca** incluyas claves, tokens ni datos personales.
4. Actualiza el `CHANGELOG.md` en la sección `[Unreleased]`.

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta [LICENSE](LICENSE) para más detalles.

---

<div align="center">
  Hecho con 💜 para Termux · <a href="https://github.com/jephersonRD">@jephersonRD</a>
</div>
