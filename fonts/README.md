# Alatar Fonts

This directory contains font-related configuration for the Alatar system.

## Required Fonts

### Ancient Medium

The Alatar system uses the **Ancient Medium** font for:
- SDDM login screen
- System UI elements (when configured)

**Installation:**

1. Download Ancient Medium font (if you don't have it):
   - The font should be `Ancient Medium.ttf`
   - Place it in `~/.fonts/` directory

2. Install system-wide (required for SDDM):
   ```bash
   sudo mkdir -p /usr/share/fonts/truetype/ancient
   sudo cp ~/.fonts/"Ancient Medium.ttf" /usr/share/fonts/truetype/ancient/
   sudo fc-cache -f
   ```

   Or run the SDDM install script which does this automatically:
   ```bash
   sudo ~/.alatar/alatar_dots/sddm/install.sh
   ```

3. Verify installation:
   ```bash
   fc-list | grep -i ancient
   ```

   You should see:
   ```
   /usr/share/fonts/truetype/ancient/Ancient Medium.ttf: Ancient:style=Medium
   ```

## Font Deployment

User fonts should be placed in `~/.fonts/` and will be automatically picked up by Fontconfig.

System fonts (needed for SDDM and other root-level services) must be installed in `/usr/share/fonts/` and require root privileges.

## Alternative Fonts

If you prefer a different font for SDDM, edit:
- `alatar_dots/wallust/templates/sddm-theme.conf` - Change the `font=` line
- `alatar_dots/sddm/alatar-theme/Main.qml` - Update `fontFamily` property default

Then regenerate and reinstall:
```bash
wallust run ~/.config/wallpaper.png
sudo cp ~/.alatar/alatar_dots/sddm/alatar-theme/theme.conf /usr/share/sddm/themes/alatar/theme.conf
```
