#!/usr/bin/env bash
# ==============================================================================
# FHAWXBAWX v1.0 // OPENBOX DESKTOP PROVISIONER (DEBIAN 13 TRIXIE)
# ==============================================================================
# Target:    Fresh Debian 13 (Trixie) CLI-only install (amd64 / arm64)
# Aesthetic: Monochromatic Burnt Orange (#CC5500) on Pure Black (#000000)
# Features:  Native X11 LightDM + Openbox + Tint2 + Rofi + RustDesk + Steam Link
# Provenance: Orchestrated by Rykr Framework v4.0 (Genesis Pipeline)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# MODULE 1: PRIVILEGE & TARGET USER RESOLUTION
# ==============================================================================
if [ "$(id -u)" -ne 0 ]; then
    echo "[*] Sudo elevation required. Re-executing as root..."
    exec sudo -E bash "$0" "$@"
fi

TARGET_USER=""
if [ -n "${1:-}" ]; then
    TARGET_USER="$1"
elif [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}' /etc/passwd || true)
fi

if [ -z "$TARGET_USER" ] || ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "[-] Error: Could not resolve a valid non-root target user. Pass username as argument: sudo $0 <username>" >&2
    exit 1
fi

TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
export DEBIAN_FRONTEND=noninteractive

echo "=================================================================="
echo "  FHAWXBAWX v1.0 // PROVISIONING FOR: $TARGET_USER ($TARGET_HOME)"
echo "=================================================================="

# ==============================================================================
# MODULE 2: CORE X11, OPENBOX, AUDIO & FLATPAK STACK
# ==============================================================================
echo "[+] [Module 2] Updating APT indices and installing core Openbox + X11 stack..."
apt-get update -y
apt-get install -y \
    xorg \
    x11-xserver-utils \
    dbus-x11 \
    lightdm \
    lightdm-gtk-greeter \
    openbox \
    obconf \
    lxappearance \
    lxpolkit \
    tint2 \
    rofi \
    nitrogen \
    xfce4-terminal \
    thunar \
    mousepad \
    xclip \
    scrot \
    fonts-firacode \
    gnome-themes-extra \
    pipewire-audio \
    pavucontrol \
    flatpak \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    python3 \
    curl \
    wget \
    jq \
    ca-certificates

# ==============================================================================
# MODULE 3: RUSTDESK (NATIVE X11 .DEB) & STEAM LINK (FLATHUB FLATPAK)
# ==============================================================================
echo "[+] [Module 3a] Installing RustDesk (latest official Debian .deb)..."
RUSTDESK_STATUS="SKIPPED (download failed)"
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64) RD_PATTERN="x86_64\.deb$" ;;
    arm64) RD_PATTERN="aarch64\.deb$" ;;
    *)     RD_PATTERN="" ;;
esac

if [ -n "$RD_PATTERN" ]; then
    RD_URL=$(curl -fsSL "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" 2>/dev/null \
        | jq -r --arg pat "$RD_PATTERN" '.assets[]?.browser_download_url | select(test($pat))' \
        | head -n 1 || true)

    if [ -n "$RD_URL" ]; then
        RD_TMP="/tmp/rustdesk_fhawxbawx.deb"
        echo "    Downloading: $RD_URL"
        if curl -fL --retry 2 -o "$RD_TMP" "$RD_URL"; then
            if apt-get install -y "$RD_TMP"; then
                systemctl enable rustdesk.service 2>/dev/null || true
                RUSTDESK_STATUS="INSTALLED ($(basename "$RD_URL"))"
            else
                echo "[!] Warning: RustDesk apt install failed; continuing DE setup."
            fi
            rm -f "$RD_TMP"
        else
            echo "[!] Warning: RustDesk download failed; continuing DE setup."
        fi
    else
        echo "[!] Warning: Could not query RustDesk GitHub release (offline or rate-limited); continuing DE setup."
    fi
else
    echo "[!] Warning: Unsupported architecture '$ARCH' for automatic RustDesk .deb install."
fi

echo "[+] [Module 3b] Installing Steam Link via Flathub..."
STEAMLINK_STATUS="SKIPPED (Flathub error)"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
if flatpak install -y --noninteractive flathub com.valvesoftware.SteamLink; then
    STEAMLINK_STATUS="INSTALLED (com.valvesoftware.SteamLink)"
else
    echo "[!] Warning: Steam Link Flatpak install failed; you can retry after reboot with: flatpak install flathub com.valvesoftware.SteamLink"
fi

mkdir -p /usr/local/share/applications
cat << 'EOF' > /usr/local/share/applications/fhawx-steamlink.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam Link
Comment=Stream games from another PC via Steam Link
Icon=com.valvesoftware.SteamLink
Exec=flatpak run com.valvesoftware.SteamLink
Terminal=false
StartupNotify=true
Categories=Game;Network;
EOF

# ==============================================================================
# MODULE 4: FHAWXBAWX VISUAL IDENTITY (#CC5500 ON #000000, FIRA CODE)
# ==============================================================================
echo "[+] [Module 4] Applying FhawxBawx Burnt Orange Visual Identity..."

# --- 4a. LightDM Session Pinning & FhawxTDE-Style Login Greeter ---
mkdir -p /etc/lightdm/lightdm.conf.d
cat << 'EOF' > /etc/lightdm/lightdm.conf.d/50-fhawxbawx.conf
[Seat:*]
user-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

cat << 'EOF' > /etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background = #000000
theme-name = Adwaita-dark
font-name = Fira Code 11
xft-antialias = true
xft-rgba = rgb
show-clock = true
clock-format = %Y-%m-%d  %H:%M
indicators = ~host;~spacer;~clock;~spacer;~session;~power
position = 50%,center 50%,center
default-user-image = #avatar-default
EOF

# --- 4b. Native Openbox Window Theme (/usr/share/themes/FhawxBawx) ---
mkdir -p /usr/share/themes/FhawxBawx/openbox-3
cat << 'EOF' > /usr/share/themes/FhawxBawx/openbox-3/themerc
# FhawxBawx Openbox Theme (Monochromatic Burnt Orange #CC5500 on #000000)

border.width: 1
padding.width: 4
padding.height: 3
window.handle.width: 0
window.client.padding.width: 0
window.client.padding.height: 0
menu.overlap.x: -2
menu.overlap.y: 0

# Active Window
window.active.border.color: #CC5500
window.active.title.bg: flat solid
window.active.title.bg.color: #000000
window.active.title.separator.color: #CC5500
window.active.label.bg: parentrelative
window.active.label.text.color: #CC5500
window.active.button.unpressed.bg: parentrelative
window.active.button.unpressed.image.color: #CC5500
window.active.button.pressed.bg: flat solid
window.active.button.pressed.bg.color: #CC5500
window.active.button.pressed.image.color: #000000
window.active.button.hover.bg: flat solid
window.active.button.hover.bg.color: #331500
window.active.button.hover.image.color: #FF7722
window.active.button.disabled.bg: parentrelative
window.active.button.disabled.image.color: #442200

# Inactive Window
window.inactive.border.color: #331500
window.inactive.title.bg: flat solid
window.inactive.title.bg.color: #000000
window.inactive.title.separator.color: #331500
window.inactive.label.bg: parentrelative
window.inactive.label.text.color: #663311
window.inactive.button.unpressed.bg: parentrelative
window.inactive.button.unpressed.image.color: #663311
window.inactive.button.pressed.bg: parentrelative
window.inactive.button.pressed.image.color: #CC5500
window.inactive.button.disabled.bg: parentrelative
window.inactive.button.disabled.image.color: #221100

# Menus
menu.border.width: 1
menu.border.color: #CC5500
menu.title.bg: flat solid
menu.title.bg.color: #000000
menu.title.text.color: #CC5500
menu.title.text.justify: left
menu.items.bg: flat solid
menu.items.bg.color: #000000
menu.items.text.color: #CC5500
menu.items.disabled.text.color: #552800
menu.items.active.bg: flat solid
menu.items.active.bg.color: #CC5500
menu.items.active.text.color: #000000
menu.separator.color: #331500
menu.separator.width: 1
menu.separator.padding.width: 4
menu.separator.padding.height: 3

# OSD (Alt+Tab)
osd.border.width: 1
osd.border.color: #CC5500
osd.bg: flat solid
osd.bg.color: #000000
osd.label.bg: parentrelative
osd.label.text.color: #CC5500
osd.hilight.bg: flat solid
osd.hilight.bg.color: #CC5500
osd.unhilight.bg: flat solid
osd.unhilight.bg.color: #221100
EOF

# --- 4c. Backup Existing Openbox Config (Idempotency Safety) ---
OB_DIR="$TARGET_HOME/.config/openbox"
if [ -d "$OB_DIR" ] && [ ! -f "$OB_DIR/.fhawxbawx_managed" ]; then
    BACKUP_DIR="${OB_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "    Backing up existing Openbox config to: $BACKUP_DIR"
    cp -a "$OB_DIR" "$BACKUP_DIR"
fi

mkdir -p \
    "$OB_DIR" \
    "$TARGET_HOME/.config/tint2" \
    "$TARGET_HOME/.config/rofi" \
    "$TARGET_HOME/.config/gtk-3.0" \
    "$TARGET_HOME/.config/xfce4/terminal"

# --- 4d. Openbox rc.xml (Theme + Keybindings via Stdlib XML) ---
cp -f /etc/xdg/openbox/rc.xml "$OB_DIR/rc.xml"
python3 - "$OB_DIR/rc.xml" << 'PYEOF'
import sys
import xml.etree.ElementTree as ET

rc_path = sys.argv[1]
NS_URI = "http://openbox.org/3.4/rc"
ns = {"ob": NS_URI}
ET.register_namespace("", NS_URI)

tree = ET.parse(rc_path)
root = tree.getroot()

# Apply FhawxBawx theme & Fira Code font
theme = root.find("ob:theme", ns)
if theme is not None:
    name_el = theme.find("ob:name", ns)
    if name_el is not None:
        name_el.text = "FhawxBawx"
    for font_el in theme.findall("ob:font", ns):
        fn = font_el.find("ob:name", ns)
        fs = font_el.find("ob:size", ns)
        if fn is not None:
            fn.text = "Fira Code"
        if fs is not None:
            fs.text = "10"

# Inject FhawxBawx keybindings
kb = root.find("ob:keyboard", ns)
if kb is not None:
    bindings = [
        ("W-Return", "Execute", "xfce4-terminal"),
        ("W-r", "Execute", "rofi -show drun"),
        ("W-e", "Execute", "thunar"),
        ("W-q", "Close", None),
        ("Print", "Execute", "scrot '%Y-%m-%d_%H%M%S.png' -e 'mv $f ~/Desktop/ 2>/dev/null || mv $f ~/'"),
    ]
    for key, act_name, cmd in bindings:
        kbind = ET.SubElement(kb, f"{{{NS_URI}}}keybind", {"key": key})
        act = ET.SubElement(kbind, f"{{{NS_URI}}}action", {"name": act_name})
        if cmd:
            cmd_el = ET.SubElement(act, f"{{{NS_URI}}}command")
            cmd_el.text = cmd

tree.write(rc_path, encoding="UTF-8", xml_declaration=True)
PYEOF

# --- 4e. Openbox Right-Click Menu (menu.xml) ---
cat << 'EOF' > "$OB_DIR/menu.xml"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="FhawxBawx">
    <item label="Terminal (Super+Enter)">
      <action name="Execute"><command>xfce4-terminal</command></action>
    </item>
    <item label="App Launcher (Super+R)">
      <action name="Execute"><command>rofi -show drun</command></action>
    </item>
    <item label="Files (Thunar)">
      <action name="Execute"><command>thunar</command></action>
    </item>
    <item label="Text Editor (Mousepad)">
      <action name="Execute"><command>mousepad</command></action>
    </item>
    <separator />
    <item label="Steam Link">
      <action name="Execute"><command>flatpak run com.valvesoftware.SteamLink</command></action>
    </item>
    <item label="RustDesk">
      <action name="Execute"><command>rustdesk</command></action>
    </item>
    <separator />
    <menu id="settings-menu" label="System &amp; Appearance">
      <item label="Audio Mixer (pavucontrol)">
        <action name="Execute"><command>pavucontrol</command></action>
      </item>
      <item label="Openbox Config (obconf)">
        <action name="Execute"><command>obconf</command></action>
      </item>
      <item label="GTK Appearance (lxappearance)">
        <action name="Execute"><command>lxappearance</command></action>
      </item>
      <item label="Reconfigure Openbox">
        <action name="Reconfigure" />
      </item>
    </menu>
    <separator />
    <item label="Log Out">
      <action name="Exit"><prompt>yes</prompt></action>
    </item>
    <item label="Reboot">
      <action name="Execute"><command>systemctl reboot</command></action>
    </item>
    <item label="Power Off">
      <action name="Execute"><command>systemctl poweroff</command></action>
    </item>
  </menu>
</openbox_menu>
EOF

# --- 4f. Tint2 Slim Bottom Bar (tint2rc) ---
cat << 'EOF' > "$TARGET_HOME/.config/tint2/tint2rc"
# FhawxBawx Tint2 Panel (#CC5500 on #000000)

# Backgrounds
rounded = 0
border_width = 1
border_sides = T
background_color = #000000 100
border_color = #CC5500 100

rounded = 0
border_width = 1
border_sides = B
background_color = #1A0A00 100
border_color = #CC5500 100

rounded = 0
border_width = 0
background_color = #000000 100
border_color = #331500 100

# Panel
panel_items = TSBC
panel_size = 100% 26
panel_margin = 0 0
panel_padding = 4 2 4
panel_background_id = 1
panel_position = bottom center horizontal
panel_layer = top
panel_monitor = all
strut_policy = follow_size

# Taskbar
taskbar_mode = single_desktop
taskbar_padding = 2 0 4
taskbar_background_id = 0
taskbar_active_background_id = 0
task_maximum_size = 200 24
task_padding = 6 2 4
task_font = Fira Code 9
task_font_color = #884411 100
task_active_font_color = #CC5500 100
task_background_id = 3
task_active_background_id = 2
task_icon = 1
task_text = 1
mouse_left = toggle_iconify
mouse_middle = close

# System Tray
systray_padding = 4 2 6
systray_background_id = 0
systray_icon_size = 18

# Battery (shows only if battery exists)
battery_low_status = 15
bat1_font = Fira Code 9
bat1_format = BAT %p
battery_font_color = #CC5500 100
battery_padding = 4 0

# Clock
time1_format = %Y-%m-%d  %H:%M
time1_font = Fira Code 9
clock_font_color = #CC5500 100
clock_padding = 6 0
clock_background_id = 0
EOF

# --- 4g. Rofi Launcher Theme (config.rasi) ---
cat << 'EOF' > "$TARGET_HOME/.config/rofi/config.rasi"
configuration {
    modi: "drun,run";
    font: "Fira Code 11";
    show-icons: false;
    display-drun: "FHAWXBAWX >";
    display-run: "CMD >";
}

* {
    bg: #000000;
    fg: #CC5500;
    fg-dim: #663311;
    border-col: #CC5500;
    background-color: @bg;
    text-color: @fg;
}

window {
    width: 45%;
    border: 2px;
    border-color: @border-col;
    padding: 12px;
}

mainbox {
    spacing: 8px;
}

inputbar {
    padding: 6px;
    border: 0 0 1px 0;
    border-color: @border-col;
    children: [ prompt, entry ];
}

prompt {
    padding: 0 10px 0 0;
    text-color: @fg;
}

entry {
    text-color: @fg;
}

listview {
    lines: 10;
    scrollbar: false;
    spacing: 4px;
}

element {
    padding: 4px 8px;
}

element normal.normal {
    background-color: @bg;
    text-color: @fg;
}

element selected.normal {
    background-color: @fg;
    text-color: @bg;
}
EOF

# --- 4h. GTK2 / GTK3 Dark Base + Burnt Orange Accents ---
cat << 'EOF' > "$TARGET_HOME/.gtkrc-2.0"
gtk-theme-name="Adwaita-dark"
gtk-font-name="Fira Code 10"
EOF

cat << 'EOF' > "$TARGET_HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Adwaita-dark
gtk-font-name=Fira Code 10
gtk-application-prefer-dark-theme=1
EOF

cat << 'EOF' > "$TARGET_HOME/.config/gtk-3.0/gtk.css"
/* FhawxBawx non-destructive Burnt Orange GTK3 accents on Adwaita-dark */
@define-color theme_selected_bg_color #CC5500;
@define-color theme_selected_fg_color #000000;

selection {
    background-color: #CC5500;
    color: #000000;
}

entry:focus, textview:focus {
    border-color: #CC5500;
}
EOF

# --- 4i. XFCE4 Terminal Burnt Orange Profile ---
cat << 'EOF' > "$TARGET_HOME/.config/xfce4/terminal/terminalrc"
[Configuration]
ColorForeground=#CC5500
ColorBackground=#000000
ColorCursor=#CC5500
FontName=Fira Code 11
MiscMenubarDefault=FALSE
MiscBordersDefault=TRUE
MiscAlwaysShowTabs=FALSE
ScrollingLines=5000
EOF

# ==============================================================================
# MODULE 5: SESSION WIRING, OWNERSHIP & ENABLEMENT
# ==============================================================================
echo "[+] [Module 5] Wiring Openbox autostart, permissions, and LightDM..."

# Openbox autostart MUST be an executable FILE (zero unclutter / zero picom)
cat << 'EOF' > "$OB_DIR/autostart"
#!/bin/sh
# FhawxBawx Openbox Autostart (RustDesk-safe: no unclutter, no picom)
xsetroot -solid "#000000" &
xset s off &
xset -dpms &
lxpolkit &
tint2 &
EOF
chmod +x "$OB_DIR/autostart"
touch "$OB_DIR/.fhawxbawx_managed"

# Ensure target user owns all generated configs
chown -R "$TARGET_USER:$TARGET_USER" \
    "$TARGET_HOME/.config" \
    "$TARGET_HOME/.gtkrc-2.0"

# Enable LightDM graphical login manager
systemctl enable lightdm.service

echo ""
echo "=================================================================="
echo "  FHAWXBAWX v1.0 INSTALLATION COMPLETE"
echo "=================================================================="
echo "  Target User : $TARGET_USER ($TARGET_HOME)"
echo "  Desktop     : Openbox + LightDM (X11) + Tint2 + Rofi"
echo "  Aesthetic   : Burnt Orange (#CC5500) on Pure Black (#000000)"
echo "  RustDesk    : $RUSTDESK_STATUS"
echo "  Steam Link  : $STEAMLINK_STATUS"
echo ""
echo "  Keybindings :"
echo "    Super + Enter  -> Terminal (xfce4-terminal)"
echo "    Super + R      -> App Launcher (Rofi)"
echo "    Super + E      -> File Manager (Thunar)"
echo "    Super + Q      -> Close Window"
echo "    Right-Click    -> FhawxBawx Desktop Menu"
echo ""
echo "  Next Step   : sudo reboot"
echo "=================================================================="
