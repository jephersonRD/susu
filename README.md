<div align="center">

<!-- Reemplaza con tu banner: sube assets/banner.png -->
<img src="assets/banner.png" alt="susu" width="340"/>

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
<img src="assets/1.png" alt="susu" width="340"/>

## ⚡ Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/jephersonRD/susu/main/install.sh | bash
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
