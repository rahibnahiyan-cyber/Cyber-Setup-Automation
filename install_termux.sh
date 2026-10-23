#!/data/data/com.termux/files/usr/bin/bash
set -u

LOG_FILE="$HOME/termux_kali_setup.log"
INSTALLER_URL="https://raw.githubusercontent.com/xiv3r/Kali-Linux-Termux/refs/heads/main/kali.sh"
INSTALLER_FILE="$HOME/install.sh"

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
    header "Termux + Kali Linux Setup"
    echo -e "${BLUE}This script will:${RESET}"
    echo "  1) Update and upgrade packages"
    echo "  2) Enable storage access"
    echo "  3) Install missing dependencies"
    echo "  4) Download and run Kali installer"
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

install_or_skip() {
    local pkg_name="$1"

    if is_installed "$pkg_name"; then
        info "Skipped: $pkg_name is already installed"
        return 0
    fi

    info "Installing: $pkg_name"
    if pkg install -y "$pkg_name"; then
        success "Installed via pkg: $pkg_name"
        return 0
    fi

    warn "pkg install failed for $pkg_name. Trying apt fallback..."
    if apt update >/dev/null 2>&1 && apt install -y "$pkg_name"; then
        success "Installed via apt: $pkg_name"
        return 0
    fi

    error "Failed to install $pkg_name using pkg and apt"
    return 1
}

download_file() {
    local url="$1"
    local dest="$2"

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

print_summary() {
    echo -e "\n${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${WHITE}Setup Summary${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo -e "${GREEN}Log file:${RESET} $LOG_FILE"
    echo -e "${GREEN}Installer file:${RESET} $INSTALLER_FILE"
    echo -e "${GREEN}Status:${RESET} ${BOLD}Completed${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}\n"
}

main() {
    check_termux
    confirm_continue

    info "Starting Termux setup..."

    info "Updating Termux packages..."
    pkg update >/dev/null 2>&1 || warn "pkg update failed; continuing..."
    pkg upgrade -y >/dev/null 2>&1 || warn "pkg upgrade failed; continuing..."

    info "Enabling storage access..."
    termux-setup-storage >/dev/null 2>&1 || warn "termux-setup-storage failed; continuing..."

    for pkg_name in nmap curl wget git proot termux-services; do
        install_or_skip "$pkg_name" || warn "Continuing without $pkg_name"
    done

    info "Refreshing package index..."
    pkg update >/dev/null 2>&1 || warn "Final pkg update failed; continuing..."
    pkg upgrade -y >/dev/null 2>&1 || warn "Final pkg upgrade failed; continuing..."

    info "Downloading Kali installer..."
    rm -f "$INSTALLER_FILE"
    if ! download_file "$INSTALLER_URL" "$INSTALLER_FILE"; then
        error "Failed to download Kali installer"
        exit 1
    fi

    chmod +x "$INSTALLER_FILE" || {
        error "Failed to make installer executable"
        exit 1
    }

    info "Running Kali installer..."
    if bash "$INSTALLER_FILE"; then
        success "Kali installation completed successfully."
    else
        error "Kali installer failed."
        exit 1
    fi

    print_summary
}

main "$@"
