#!/data/data/com.termux/files/usr/bin/bash
set -u

LOG_FILE="$HOME/termux_kali_setup.log"
INSTALLER_URL="https://raw.githubusercontent.com/xiv3r/Kali-Linux-Termux/refs/heads/main/kali.sh"
INSTALLER_FILE="$HOME/install.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE" >&2
}

err() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

check_termux() {
    if [ -z "${PREFIX:-}" ] || ! echo "$PREFIX" | grep -q "com.termux"; then
        err "This script must be run inside Termux."
        exit 1
    fi
}

confirm_continue() {
    echo
    echo "========================================"
    echo "Termux + Kali Linux Setup"
    echo "========================================"
    echo "This script will:"
    echo "  1) Update/upgrade packages"
    echo "  2) Enable storage access"
    echo "  3) Install missing tools"
    echo "  4) Download and run Kali installer"
    echo "========================================"
    echo "Do you want to continue? [Y/n]"
    read -r answer
    case "${answer:-Y}" in
        [Yy]|[Yy][Ee][Ss])
            ;;
        *)
            echo "Aborted by user."
            exit 0
            ;;
    esac
}

is_installed() {
    pkg_name="$1"
    [ -n "$pkg_name" ] || return 1

    if pkg list-installed 2>/dev/null | grep -qi "^${pkg_name}[[:space:]]"; then
        return 0
    fi

    if command -v dpkg >/dev/null 2>&1 && dpkg -s "$pkg_name" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

install_or_skip() {
    pkg_name="$1"

    if is_installed "$pkg_name"; then
        log "Skipped: $pkg_name is already installed"
        return 0
    fi

    log "Installing: $pkg_name"
    if pkg install -y "$pkg_name"; then
        log "Installed via pkg: $pkg_name"
        return 0
    fi

    warn "pkg install failed for $pkg_name. Trying apt fallback..."
    if apt update >/dev/null 2>&1 && apt install -y "$pkg_name"; then
        log "Installed via apt: $pkg_name"
        return 0
    fi

    err "Failed to install $pkg_name using pkg and apt"
    return 1
}

download_file() {
    url="$1"
    dest="$2"

    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$url" -o "$dest"; then
            return 0
        fi
    fi

    if command -v wget >/dev/null 2>&1; then
        if wget -qO "$dest" "$url"; then
            return 0
        fi
    fi

    return 1
}

main() {
    check_termux
    confirm_continue

    log "Starting Termux setup..."

    pkg update >/dev/null 2>&1 || warn "pkg update failed; continuing..."
    pkg upgrade -y >/dev/null 2>&1 || warn "pkg upgrade failed; continuing..."

    termux-setup-storage >/dev/null 2>&1 || warn "termux-setup-storage failed; continuing..."

    for pkg_name in nmap curl wget git proot; do
        install_or_skip "$pkg_name" || warn "Continuing without $pkg_name"
    done

    log "Refreshing package index..."
    pkg update >/dev/null 2>&1 || warn "Final pkg update failed; continuing..."
    pkg upgrade -y >/dev/null 2>&1 || warn "Final pkg upgrade failed; continuing..."

    log "Downloading Kali installer..."
    rm -f "$INSTALLER_FILE"
    if ! download_file "$INSTALLER_URL" "$INSTALLER_FILE"; then
        err "Failed to download Kali installer"
        exit 1
    fi

    chmod +x "$INSTALLER_FILE" || {
        err "Failed to make installer executable"
        exit 1
    }

    log "Running Kali installer..."
    if bash "$INSTALLER_FILE"; then
        log "Kali installation completed successfully."
    else
        err "Kali installer failed."
        exit 1
    fi
}

main "$@"
