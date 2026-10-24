#!/data/data/com.termux/files/usr/bin/bash
set -u
set -o pipefail

LOG_FILE="$HOME/termux_nethunter_setup.log"
INSTALLER_URL="https://offs.ec/2MceZWr"
INSTALLER_FILE="$HOME/install-nethunter-termux"

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
WHITE='\033[97m'
BOLD='\033[1m'
RESET='\033[0m'

log() {
    local level="$1"
    shift
    local msg="$*"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${msg}" | tee -a "$LOG_FILE"
}

info() { log "INFO" "$*"; }
warn() { log "WARN" "${YELLOW}${*}${RESET}" >&2; }
error() { log "ERROR" "${RED}${*}${RESET}" >&2; }
success() { log "OK" "${GREEN}${*}${RESET}"; }

header() {
    echo -e "\n${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${WHITE}$*${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"
}

check_termux() {
    if [ -z "${PREFIX:-}" ] || ! echo "$PREFIX" | grep -q "com.termux"; then
        error "This script must be run inside Termux."
        exit 1
    fi
}

confirm_continue() {
    header "Termux + NetHunter Setup"
    echo -e "${BLUE}This script will:${RESET}"
    echo "  1) Run pkg update"
    echo "  2) Check / enable storage"
    echo "  3) Install wget if missing"
    echo "  4) Download official NetHunter installer"
    echo "  5) Run the installer"
    echo ""
    read -r -p "Do you want to continue? [Y/n]: " answer
    case "${answer:-Y}" in
        [Yy]|[Yy][Ee][Ss])
            ;;
        *)
            echo -e "${YELLOW}Aborted by user.${RESET}"
            exit 0
            ;;
    esac
}

is_installed() {
    local pkg_name="$1"
    [ -n "$pkg_name" ] || return 1

    if pkg list-installed 2>/dev/null | grep -qi "^${pkg_name}[[:space:]]"; then
        return 0
    fi

    if command -v dpkg >/dev/null 2>&1 && dpkg -s "$pkg_name" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

is_storage_ready() {
    [ -d "/sdcard" ] || [ -d "/storage/emulated/0" ]
}

run_and_log() {
    local desc="$1"
    shift
    info "$desc"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

setup_storage() {
    if is_storage_ready; then
        info "Skipped: storage is already available"
        return 0
    fi

    info "Configuring storage..."
    if run_and_log "termux-setup-storage" termux-setup-storage; then
        success "Storage setup completed"
        return 0
    fi

    warn "termux-setup-storage failed; continuing..."
    return 1
}

ensure_wget() {
    if is_installed wget; then
        info "Skipped: wget is already installed"
        return 0
    fi

    info "Installing wget..."
    if run_and_log "pkg install wget" pkg install wget -y; then
        success "wget installed via pkg"
        return 0
    fi

    warn "pkg install wget failed. Trying apt fallback..."
    if run_and_log "apt update" apt update; then
        :
    fi

    if run_and_log "apt install wget" apt install wget -y; then
        success "wget installed via apt"
        return 0
    fi

    error "Failed to install wget"
    return 1
}

download_installer() {
    if [ -f "$INSTALLER_FILE" ]; then
        info "Skipped: installer already exists at $INSTALLER_FILE"
        return 0
    fi

    info "Downloading NetHunter installer..."
    if run_and_log "wget -O $INSTALLER_FILE $INSTALLER_URL" wget -O "$INSTALLER_FILE" "$INSTALLER_URL"; then
        success "Installer downloaded successfully"
        return 0
    fi

    warn "wget download failed. Trying curl fallback..."
    if run_and_log "curl -L -o $INSTALLER_FILE $INSTALLER_URL" curl -L -o "$INSTALLER_FILE" "$INSTALLER_URL"; then
        success "Installer downloaded via curl"
        return 0
    fi

    error "Failed to download NetHunter installer"
    return 1
}

run_installer() {
    chmod +x "$INSTALLER_FILE" || {
        error "Failed to make installer executable"
        exit 1
    }

    info "Running installer with the same flow as your manual process..."
    if run_and_log "./install-nethunter-termux" bash "$INSTALLER_FILE"; then
        success "NetHunter installer completed"
        return 0
    fi

    error "NetHunter installer failed"
    return 1
}

print_summary() {
    echo -e "\n${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${WHITE}Setup Summary${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo -e "${GREEN}Log file:${RESET} $LOG_FILE"
    echo -e "${GREEN}Installer file:${RESET} $INSTALLER_FILE"
    echo -e "${GREEN}URL:${RESET} $INSTALLER_URL"
    echo -e "${GREEN}Status:${RESET} ${BOLD}Completed${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}\n"
}

main() {
    check_termux
    confirm_continue

    info "Starting NetHunter setup..."

    if run_and_log "pkg update" pkg update; then
        :
    else
        warn "pkg update failed; continuing..."
    fi

    setup_storage
    ensure_wget
    download_installer
    run_installer
    print_summary
}

main "$@"
