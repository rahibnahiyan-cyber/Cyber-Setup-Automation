#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

LOG_FILE="$HOME/termux_kali_install.log"
INSTALLER_URL="https://raw.githubusercontent.com/xiv3r/Kali-Linux-Termux/refs/heads/main/kali.sh"
INSTALLER_FILE="$HOME/install.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" | tee -a "$LOG_FILE" >&2
}

error_exit() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
    exit 1
}

check_termux() {
    if [[ -z "${PREFIX:-}" ]] || [[ "$PREFIX" != *"com.termux"* ]]; then
        error_exit "This script must be run inside Termux."
    fi
}

confirm_continue() {
    echo
    echo "========================================"
    echo "Termux + Kali Linux Installer"
    echo "========================================"
    echo "This script will:"
    echo "  1) Update and upgrade Termux packages"
    echo "  2) Enable storage access"
    echo "  3) Install required tools"
    echo "  4) Download and run the Kali Linux installer"
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

install_dependencies() {
    log "Updating Termux packages..."
    pkg update && pkg upgrade -y || error_exit "Failed during pkg update/upgrade"

    log "Enabling storage access..."
    termux-setup-storage || warn "termux-setup-storage returned a non-zero exit code; continuing..."

    log "Installing required packages..."
    pkg install -y nmap curl wget git proot || error_exit "Failed to install required packages"

    log "Final package refresh..."
    pkg update && pkg upgrade -y || warn "Final pkg update/upgrade failed; continuing..."
}

download_installer() {
    log "Downloading Kali Linux installer script..."
    rm -f "$INSTALLER_FILE"

    if ! wget -qO "$INSTALLER_FILE" "$INSTALLER_URL"; then
        error_exit "Download failed. Please check your internet connection or the installer URL."
    fi

    chmod +x "$INSTALLER_FILE" || error_exit "Failed to make installer executable"
    log "Installer downloaded successfully: $INSTALLER_FILE"
}

run_installer() {
    echo
    log "Starting Kali Linux installation..."
    "$INSTALLER_FILE" || error_exit "Kali Linux installer failed to run"
}

main() {
    check_termux
    confirm_continue
    install_dependencies
    download_installer
    run_installer

    echo
    echo "========================================"
    echo "Kali installation process finished."
    echo "If the installer asks for more input, follow the on-screen instructions."
    echo "You may need to restart Termux afterward."
    echo "========================================"
}

main "$@"
