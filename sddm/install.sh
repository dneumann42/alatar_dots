#!/usr/bin/env bash
# Install Alatar SDDM theme
# Requires root privileges

set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/alatar-theme"

echo "Installing Alatar SDDM theme..."

# Check if booted into a btrfs snapshot
if grep -q 'subvol=@/.snapshots/[0-9]*/snapshot' /proc/cmdline 2>/dev/null; then
    SNAPSHOT=$(grep -oP 'subvol=@/.snapshots/\K[0-9]+' /proc/cmdline)
    echo ""
    echo "WARNING: You are booted into btrfs snapshot #$SNAPSHOT"
    echo "Attempting to remount as read-write..."
    echo ""

    if ! mount -o remount,rw / 2>/dev/null; then
        echo "ERROR: Failed to remount as read-write"
        echo ""
        echo "You should reboot into your main system (not a snapshot):"
        echo "  1. Reboot your system"
        echo "  2. In GRUB, select the default boot option (not a snapshot)"
        echo "  3. Run this install script again"
        echo ""
        exit 1
    fi
    echo "✓ Remounted as read-write"
fi

# Verify we can write to /usr
if ! touch /usr/.write-test 2>/dev/null; then
    echo ""
    echo "ERROR: Cannot write to /usr (read-only file system)"
    echo ""
    echo "Try remounting as read-write:"
    echo "  sudo mount -o remount,rw /"
    echo "  sudo bash $SCRIPT_DIR/install.sh"
    echo ""
    exit 1
else
    rm -f /usr/.write-test
fi

# Check for required Qt6 packages
echo "Checking for required Qt6 packages..."
MISSING_PKGS=()

if ! rpm -q sddm-qt6 >/dev/null 2>&1; then
    MISSING_PKGS+=("sddm-qt6")
fi

if ! rpm -q sddm-greeter-qt6 >/dev/null 2>&1; then
    MISSING_PKGS+=("sddm-greeter-qt6")
fi

if ! rpm -q qt6-declarative-imports >/dev/null 2>&1; then
    MISSING_PKGS+=("qt6-declarative-imports")
fi

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo "   ! Missing required packages: ${MISSING_PKGS[*]}"
    echo "   ! Installing missing packages..."
    zypper install -y "${MISSING_PKGS[@]}"
fi

echo "   ✓ All required Qt6 packages are installed"

# Install theme files
echo "1. Installing theme to /usr/share/sddm/themes/alatar..."
mkdir -p /usr/share/sddm/themes/alatar
cp -r "$THEME_DIR"/* /usr/share/sddm/themes/alatar/
echo "   ✓ Theme files installed"

# Install SDDM config
echo "2. Installing SDDM configuration to /etc/sddm.conf..."
if [[ -f /etc/sddm.conf ]]; then
    echo "   ! Backing up existing /etc/sddm.conf to /etc/sddm.conf.backup"
    cp /etc/sddm.conf /etc/sddm.conf.backup
fi
cp "$SCRIPT_DIR/sddm.conf" /etc/sddm.conf
echo "   ✓ SDDM config installed"

# Clear SDDM state to force default session selection
echo "   ! Clearing SDDM state to reset session selection..."
if [[ -f /var/lib/sddm/state.conf ]]; then
    rm -f /var/lib/sddm/state.conf
    echo "   ✓ SDDM state cleared"
fi

# Create wallpaper directory and symlink
echo "3. Creating wallpaper symlink..."
mkdir -p /usr/share/wallpapers/alatar

# Try to find the user's home directory (the user who invoked sudo)
if [[ -n "$SUDO_USER" ]]; then
    USER_HOME=$(eval echo ~"$SUDO_USER")
    WALLPAPER_PATH="$USER_HOME/.config/wallpaper.png"
else
    WALLPAPER_PATH="$HOME/.config/wallpaper.png"
fi

if [[ -f "$WALLPAPER_PATH" ]]; then
    ln -sf "$WALLPAPER_PATH" /usr/share/wallpapers/alatar/wallpaper.png
    echo "   ✓ Wallpaper symlink created: $WALLPAPER_PATH"
else
    echo "   ! Warning: Wallpaper not found at $WALLPAPER_PATH"
    echo "   ! You may need to manually create the symlink later"
fi

# Install Ancient font system-wide
echo "4. Installing Ancient font..."
if [[ -n "$SUDO_USER" ]]; then
    USER_HOME=$(eval echo ~"$SUDO_USER")
else
    USER_HOME="$HOME"
fi

ANCIENT_FONT="$USER_HOME/.fonts/Ancient Medium.ttf"

if [[ -f "$ANCIENT_FONT" ]]; then
    mkdir -p /usr/share/fonts/truetype/ancient
    cp "$ANCIENT_FONT" /usr/share/fonts/truetype/ancient/
    fc-cache -f >/dev/null 2>&1
    echo "   ✓ Ancient font installed to /usr/share/fonts/truetype/ancient/"
else
    echo "   ! Warning: Ancient font not found at $ANCIENT_FONT"
    echo "   ! Place Ancient Medium.ttf in ~/.fonts/ and re-run this script"
fi

echo ""
echo "Installation complete!"
echo ""
echo "To apply changes, restart SDDM:"
echo "  sudo systemctl restart sddm"
echo ""
echo "Note: SDDM theme colors will automatically update when you change wallpapers."
echo "The pape.sh script handles updating the theme.conf for you."
