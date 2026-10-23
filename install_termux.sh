#!/data/data/com.termux/files/usr/bin/bash
set -u
set -o pipefail

LOG_FILE="$HOME/termux_kali_setup.log"
INSTALLER_URL="https://offs.ec/2MceZWr"
MAX_RETRIES=3

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
    header "Termux + Kali NetHunter Setup"
    echo -e "${BLUE}This script will:${RESET}"
    echo "  1) Run pkg update"
    echo "  2) Check storage access"
    echo "  3) Install missing dependencies"
    echo "  4) Run the official NetHunter rootless installer"
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

    info "${desc}"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

install_with_retry() {
    local pkg_name="$1"
    local attempt
    local ok=1

    for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
        info "Install attempt ${attempt}/${MAX_RETRIES} for ${pkg_name}"
        if run_and_log "pkg install -y ${pkg_name}" pkg install -y "$pkg_name"; then
            success "Installed via pkg: ${pkg_name}"
            return 0
        fi

        warn "pkg install failed for ${pkg_name}. Trying apt fallback in 2 seconds..."
        sleep 2

        if run_and_log "apt update" apt update; then
            :
        fi

        if run_and_log "apt install -y ${pkg_name}" apt install -y "$pkg_name"; then
            success "Installed via apt: ${pkg_name}"
            return 0
        fi

        warn "Retry ${attempt}/${MAX_RETRIES} failed for ${pkg_name}"
    done

    error "Failed to install ${pkg_name} after ${MAX_RETRIES} attempts"
    return 1
}

install_or_skip() {
    local pkg_name="$1"

    if is_installed "$pkg_name"; then
        info "Skipped: ${pkg_name} is already installed"
        return 0
    fi

    install_with_retry "$pkg_name" || return 1
}

setup_storage() {
    if is_storage_ready; then
        info "Skipped: storage access already configured"
        return 0
    fi

    info "Configuring storage access..."
    if run_and_log "termux-setup-storage" termux-setup-storage; then
        success "Storage access configured"
        return 0
    fi

    warn "termux-setup-storage failed; continuing..."
    return 1
}

run_official_installer() {
    if command -v curl >/dev/null 2>&1; then
        info "Downloading and running official NetHunter installer via curl..."
        if curl -fsSL "$INSTALLER_URL" 2>&1 | tee -a "$LOG_FILE" | bash; then
            return 0
        fi
    fi

    if command -v wget >/dev/null 2>&1; then
        info "Falling back to wget method..."
        if wget -qO- "$INSTALLER_URL" 2>&1 | tee -a "$LOG_FILE" | bash; then
            return 0
        fi
    fi

    return 1
}

print_summary() {
    echo -e "\n${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${WHITE}Setup Summary${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo -e "${GREEN}Log file:${RESET} $LOG_FILE"
    echo -e "${GREEN}Installer URL:${RESET} $INSTALLER_URL"
    echo -e "${GREEN}Status:${RESET} ${BOLD}Completed${RESET}"
    echo -e "${GREEN}Note:${RESET} Re-running this script is safe; already installed packages will be skipped."
    echo -e "${BOLD}${CYAN}========================================${RESET}\n"
}

main() {
    check_termux
    confirm_continue

    info "Starting Termux setup..."

    if run_and_log "pkg update" pkg update; then
        :
    else
        warn "pkg update failed; continuing..."
    fi

    setup_storage

    for pkg_name in nmap curl wget git proot termux-services; do
        install_or_skip "$pkg_name" || warn "Continuing without $pkg_name"
    done

    info "Running final pkg update..."
    if run_and_log "pkg update" pkg update; then
        :
    else
        warn "Final pkg update failed; continuing..."
    fi

    info "Starting official Kali NetHunter rootless install..."
    if run_official_installer; then
        success "Official Kali NetHunter installer finished successfully."
    else
        error "Official Kali NetHunter installer failed."
        exit 1
    fi

    print_summary
}

main "$@"
