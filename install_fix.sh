#!/usr/bin/env bash
# Extra Large Minimap Fix by KARAM_BO$$ — Linux installer
set -uo pipefail

TARGET_PATH="panorama/styles/hud/dota_hud_combat_events.vcss_c"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/dota_hud_combat_events.vcss_c"

VPKEDIT_VERSION="v5.0.0.4"
VPKEDIT_URL="https://github.com/craftablescience/VPKEdit/releases/download/${VPKEDIT_VERSION}/VPKEdit-Linux-Standalone-gcc-Release.zip"
VPKEDIT_LOCAL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/vpkedit"

finish() {
    echo
    read -rp "Press Enter to close..." _ || true
    exit "${1:-0}"
}

cat <<'EOF'
===================================================
  Extra Large Minimap Fix by KARAM_BO$$
===================================================
                               ##
                           @@####
                         ##########
                       ############@@
                         ############
                         ##############
                 ######    ############
             ##########    ##############
             ############    ############
             ##############    ############
         ##    ############    ##############
     ######    ##############    ############
   ##########    ############    ##############
 ############    ##############    ############
   ############    ############    ##############

EOF

read -rp "Install extralarge minimap fix? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    finish 0
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Could not find $SOURCE_FILE"
    echo "Keep dota_hud_combat_events.vcss_c next to this script."
    finish 1
fi

# ---------------------------------------------------------------- VPKEdit ---
find_vpkedit() {
    local c
    if c="$(command -v vpkeditcli 2>/dev/null)"; then echo "$c"; return 0; fi
    for c in /opt/vpkedit/vpkeditcli /usr/bin/vpkeditcli /usr/local/bin/vpkeditcli \
             "$VPKEDIT_LOCAL_DIR/vpkeditcli"; do
        [[ -x "$c" ]] && { echo "$c"; return 0; }
    done
    return 1
}

install_vpkedit() {
    echo "VPKEdit not found. It will be downloaded to: $VPKEDIT_LOCAL_DIR"
    read -rp "Download VPKEdit ${VPKEDIT_VERSION} now? (y/n): " ans
    [[ "$ans" =~ ^[Yy]$ ]] || return 1

    if ! command -v unzip >/dev/null; then
        echo "'unzip' is required. Install it with your package manager and try again."
        return 1
    fi

    local tmp; tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    echo "Downloading VPKEdit..."
    if command -v curl >/dev/null; then
        curl -fL --progress-bar -o "$tmp/vpkedit.zip" "$VPKEDIT_URL" || return 1
    elif command -v wget >/dev/null; then
        wget -q --show-progress -O "$tmp/vpkedit.zip" "$VPKEDIT_URL" || return 1
    else
        echo "Neither curl nor wget is installed."
        return 1
    fi

    mkdir -p "$VPKEDIT_LOCAL_DIR"
    unzip -oq "$tmp/vpkedit.zip" -d "$VPKEDIT_LOCAL_DIR" || return 1
    chmod +x "$VPKEDIT_LOCAL_DIR/vpkeditcli" "$VPKEDIT_LOCAL_DIR/vpkedit" 2>/dev/null
    [[ -x "$VPKEDIT_LOCAL_DIR/vpkeditcli" ]]
}

if ! VPKEDIT="$(find_vpkedit)"; then
    if ! install_vpkedit || ! VPKEDIT="$(find_vpkedit)"; then
        echo "Could not get vpkeditcli."
        echo "Install VPKEdit manually (Arch: 'paru -S vpkedit-bin'), or from:"
        echo "  https://github.com/craftablescience/VPKEdit/releases"
        finish 1
    fi
fi
echo "Using VPKEdit: $VPKEDIT"
echo

# ------------------------------------------------------------- Find Dota ---
declare -a STEAM_ROOTS=(
    "$HOME/.local/share/Steam"
    "$HOME/.steam/steam"
    "$HOME/.steam/root"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"   # Flatpak
    "$HOME/snap/steam/common/.local/share/Steam"                  # Snap
)

declare -a LIBRARIES=()
for root in "${STEAM_ROOTS[@]}"; do
    [[ -d "$root" ]] || continue
    LIBRARIES+=("$root")
    vdf="$root/steamapps/libraryfolders.vdf"
    [[ -f "$vdf" ]] || continue
    # lines look like:   "path"		"/mnt/games/SteamLibrary"
    while IFS= read -r p; do
        LIBRARIES+=("${p//\\\\/\\}")
    done < <(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$vdf")
done

declare -a FOUND=()
declare -A SEEN=()
for lib in "${LIBRARIES[@]}"; do
    d="$lib/steamapps/common/dota 2 beta"
    [[ -f "$d/game/dota/pak01_dir.vpk" ]] || continue
    real="$(realpath "$d")"
    [[ -n "${SEEN[$real]:-}" ]] && continue
    SEEN[$real]=1
    FOUND+=("$real")
done

if (( ${#FOUND[@]} == 0 )); then
    echo "Dota 2 was not found automatically."
    read -erp "Enter the path to the 'dota 2 beta' folder manually: " DOTA_PATH
    DOTA_PATH="${DOTA_PATH/#\~/$HOME}"
elif (( ${#FOUND[@]} == 1 )); then
    DOTA_PATH="${FOUND[0]}"
    echo "Found Dota 2: $DOTA_PATH"
else
    echo "Found multiple Dota 2 installations:"
    for i in "${!FOUND[@]}"; do echo "  $((i + 1))) ${FOUND[$i]}"; done
    read -rp "Enter the number of the install to use: " CHOICE
    if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#FOUND[@]} )); then
        echo "Invalid choice."
        finish 1
    fi
    DOTA_PATH="${FOUND[$((CHOICE - 1))]}"
fi

VPK="$DOTA_PATH/game/dota/pak01_dir.vpk"
if [[ ! -f "$VPK" ]]; then
    echo "pak01_dir.vpk not found at: $VPK"
    finish 1
fi

if pgrep -x dota2 >/dev/null 2>&1; then
    echo "Dota 2 appears to be running. Close it before installing the fix."
    finish 1
fi

# --------------------------------------------------------------- Replace ---
echo "Replacing file in the archive..."
"$VPKEDIT" "$VPK" --remove-file "$TARGET_PATH" --add-file "$SOURCE_FILE" "$TARGET_PATH"
rc=$?

if (( rc != 0 )); then
    echo
    echo "Something went wrong while replacing the file (error code $rc)."
    finish "$rc"
fi

cat <<'EOF'

===================================
  Done! The fix was installed successfully.
  Launch Dota 2 and check the killfeed.
===================================
EOF
finish 0
