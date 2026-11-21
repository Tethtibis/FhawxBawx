# FhawxBawx

**Ultra-lightweight Openbox Desktop Environment for Debian 13 (Trixie) CLI-only installs.**

FhawxBawx brings a functional, daily-driver graphical desktop (panel, app launcher, file manager, audio stack, RustDesk, and Steam Link) with the monochromatic **Burnt Orange (`#CC5500`) on Pure Black (`#000000`)** visual identity of [FhawxTDE](https://github.com/Tethtibis/FhawxTDE) — engineered to run smoothly on low-resource hardware (including 2GB RAM netbooks like Intel Atom N450).

---

## Key Features

* **Pure X11 + Openbox + LightDM:** Native `lightdm` + `lightdm-gtk-greeter` login screen themed to match FhawxTDE before you even enter the desktop.
* **RustDesk-Native (No Input/X11 Bugs):** Explicitly omits `unclutter`, `matchbox`, and `picom` so remote desktop sessions never lose keyboard focus or hit X11 compositor/session errors. Automatically fetches and installs the latest official RustDesk `.deb` (`amd64` / `arm64`) and enables `rustdesk.service`.
* **Steam Link Ready:** Installs `flatpak`, Flathub, `com.valvesoftware.SteamLink`, `pipewire-audio`, `pavucontrol`, and `xdg-desktop-portal-gtk` out of the box.
* **Self-Contained Burnt Orange Theme:** Zero external dotfile clones. Generates native Openbox `themerc`, `rc.xml`, `menu.xml`, `tint2rc`, `rofi` theme, `xfce4-terminal` profile, and non-destructive `Adwaita-dark` + `#CC5500` GTK2/GTK3 accents locally.
* **Idempotent & Safe:** Self-elevates via `sudo`, resolves the non-root target user cleanly, and automatically backs up any pre-existing `~/.config/openbox` directory before writing.

---

## Quick Start (Fresh Debian 13 CLI Install)

```bash
git clone https://github.com/Tethtibis/FhawxBawx.git
cd FhawxBawx
sudo bash setup-fhawxbawx.sh
sudo reboot
```

*(Optionally pass a specific username: `sudo bash setup-fhawxbawx.sh <username>`)*

---

## Default Keybindings & Navigation

| Shortcut | Action |
| :--- | :--- |
| `Super + Enter` | Open Terminal (`xfce4-terminal`) |
| `Super + R` | Application Launcher (`rofi`) |
| `Super + E` | File Manager (`thunar`) |
| `Super + Q` | Close Active Window |
| `Print` | Screenshot (`scrot`) |
| `Right-Click Desktop` | FhawxBawx System & App Menu (`menu.xml`) |

---

## Included Stack

* **Display & Window Manager:** `xorg`, `lightdm`, `lightdm-gtk-greeter`, `openbox`, `obconf`, `lxappearance`, `lxpolkit`
* **Panel & Launcher:** `tint2`, `rofi`, `nitrogen`
* **Core Utilities:** `xfce4-terminal`, `thunar`, `mousepad`, `xclip`, `scrot`, `fonts-firacode`
* **Audio & Portals:** `pipewire-audio`, `pavucontrol`, `flatpak`, `xdg-desktop-portal`, `xdg-desktop-portal-gtk`
* **Remote & Streaming:** RustDesk (official GitHub `.deb`), Steam Link (Flathub Flatpak)

---

## Roadmap

* Native graphical Openbox configuration utilities (eliminating manual XML/text editing for keybindings, menus, and panel layout).
* Hardware-tested tuning profiles for 2GB RAM netbooks and micro-PC workstations.

---

## Provenance & License

* **Systems Architecture & Hardware Verification:** Bill Fullen ([@Tethtibis](https://github.com/Tethtibis))
* **AI-Assisted Engineering:** Orchestrated using **The Rykr Framework (v4.0)** ([github.com/Tethtibis/rykr-framework](https://github.com/Tethtibis/rykr-framework)) powered by its Gemini reasoning engine under the 4-Stage Genesis Pipeline (`~plan` → `~redteam` → `~execute` → `~crystallize`).
* **License:** [MIT License](LICENSE)
