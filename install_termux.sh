#!/data/data/com.termux/files/usr/bin/bash
set -u
set -o pipefail

LOG_FILE="$HOME/nethunter_install.log"
DOC_URL="https://www.kali.org/docs/nethunter/nethunter-rootless/"
DEFAULT_URL="https://offs.ec/2MceZWr"
INSTALLER_FILE="$HOME/install-nethunter-termux"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

is_installed() {
    local pkg_name="$1"
    [ -n "$pkg_name" ] || return 1

    if pkg list-installed 2>/dev/null | grep -qi "^${pkg_name}[[:space:]]"; then
        return 0
    fi

    return 1
}

get_latest_nethunter_url() {
    local html=""
    local found_url=""

    if command -v curl >/dev/null 2>&1; then
        html=$(curl -fsSL "$DOC_URL" 2>/dev/null || true)
    elif command -v wget >/dev/null 2>&1; then
        html=$(wget -qO- "$DOC_URL" 2>/dev/null || true)
    fi

    if [ -n "$html" ]; then
        found_url=$(printf '%s\n' "$html" | grep -Eo 'https://[^"'"'"'[:space:]]+' | grep -Ei 'offs\.ec|nethunter' | head -n 1 || true)
    fi

    if [ -n "$found_url" ]; then
        echo "$found_url"
    else
        echo "$DEFAULT_URL"
    fi
}

ensure_repo() {
    local pkg_name="$1"
    if is_installed "$pkg_name"; then
        log "Skipped: $pkg_name is already installed"
        return 0
    fi

    log "Installing $pkg_name"
    pkg install -y "$pkg_name"
}

ensure_storage() {
    if [ -d "/sdcard" ] || [ -d "/storage/emulated/0" ]; then
        log "Skipped: storage already available"
        return 0
    fi

    log "Running termux-setup-storage"
    termux-setup-storage
}

main() {
    log "Checking latest NetHunter installer URL from Kali docs..."
    INSTALLER_URL="$(get_latest_nethunter_url)"
    log "Using installer URL: $INSTALLER_URL"

    log "Running pkg update"
    pkg update || log "pkg update failed; continuing..."

    ensure_repo root-repo
    ensure_repo x11-repo

    ensure_storage

    ensure_repo wget

    if [ -f "$INSTALLER_FILE" ]; then
        log "Skipped: installer file already exists at $INSTALLER_FILE"
    else
        log "Downloading NetHunter installer"
        wget -O "$INSTALLER_FILE" "$INSTALLER_URL"
    fi

    chmod +x "$INSTALLER_FILE"
    log "Running NetHunter installer"
    "$INSTALLER_FILE"
}

main "$@"
