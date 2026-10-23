#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Advanced Linux Tools Installer
# Supports Debian/Ubuntu/Kali-based systems
# ---------------------------------------------------------
# Installs:
# - zram-tools
# - VS Code
# - VirtualBox
# - Google Chrome
# - OBS Studio
#
# Reboot is intentionally NOT included.
# =========================================================

LOG_PREFIX="[INSTALL]"
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}${LOG_PREFIX} $1${NC}"
}

success() {
    echo -e "${GREEN}${LOG_PREFIX} $1${NC}"
}

warn() {
    echo -e "${YELLOW}${LOG_PREFIX} WARNING: $1${NC}"
}

fail() {
    echo -e "${RED}${LOG_PREFIX} ERROR: $1${NC}" >&2
    exit 1
}

require_root_or_sudo() {
    if [ "${EUID}" -eq 0 ]; then
        SUDO=""
    else
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            fail "sudo is required, but not installed. Please run this script as root."
        fi
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_NAME="${NAME:-Unknown Linux}"
        VERSION_ID="${VERSION_ID:-unknown}"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
        VERSION_ID="unknown"
    fi
}

ensure_apt_available() {
    if ! command -v apt-get >/dev/null 2>&1; then
        fail "This script requires apt-get (Debian/Ubuntu/Kali-based system)."
    fi
}

apt_update() {
    log "Updating package lists..."
    ${SUDO} apt-get update -qq || fail "apt-get update failed."
}

install_packages() {
    local packages=("$@")
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    log "Installing packages: ${packages[*]}"
    ${SUDO} apt-get install -y --no-install-recommends "${packages[@]}" \
        || fail "Failed to install required packages: ${packages[*]}"
}

download_file() {
    local url="$1"
    local output="$2"
    log "Downloading: ${url}"
    wget -O "${output}" "${url}" \
        || fail "Download failed: ${url}"
}

configure_zram() {
    log "Configuring zram..."
    if ! command -v zramctl >/dev/null 2>&1; then
        warn "zramctl not found. zram-tools may still install successfully."
    fi

    local zram_conf="/etc/default/zramswap"

    if [ -f "${zram_conf}" ]; then
        if ! grep -Eq '^[[:space:]]*ALGO[[:space:]]*=' "${zram_conf}" || ! grep -Eq 'ALGO=.*zstd' "${zram_conf}"; then
            echo "ALGO=zstd" | ${SUDO} tee -a "${zram_conf}" >/dev/null
        fi
    else
        echo "ALGO=zstd" | ${SUDO} tee "${zram_conf}" >/dev/null
    fi

    ${SUDO} systemctl enable --now zramswap 2>/dev/null || warn "zramswap service could not be enabled. It may not be available on this system."
    swapon --show 2>/dev/null || true
    zramctl 2>/dev/null || true
}

install_vscode() {
    log "Installing Visual Studio Code..."
    local tmp_deb="/tmp/vscode.deb"
    local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

    download_file "${vscode_url}" "${tmp_deb}"
    ${SUDO} apt-get install -y --no-install-recommends "${tmp_deb}" \
        || fail "Failed to install VS Code package."
    rm -f "${tmp_deb}"
    success "VS Code installation completed."
}

install_virtualbox() {
    log "Installing VirtualBox..."
    install_packages "virtualbox" "virtualbox-ext-pack" "dkms"

    # Ensure linux headers exist
    local headers_pkg="linux-headers-$(uname -r)"
    if ! dpkg -s "${headers_pkg}" >/dev/null 2>&1; then
        install_packages "${headers_pkg}"
    fi

    # Add user to vboxusers group if not already
    if id "${USER:-$(whoami)}" >/dev/null 2>&1; then
        local current_user="${USER:-$(whoami)}"
        if ! id -nG "${current_user}" | tr ' ' '\n' | grep -qx "vboxusers"; then
            ${SUDO} usermod -aG vboxusers "${current_user}" || warn "Could not add ${current_user} to vboxusers."
        fi
    fi

    ${SUDO} dpkg-reconfigure virtualbox-dkms >/dev/null 2>&1 || warn "virtualbox-dkms reconfiguration skipped or unavailable."
    ${SUDO} modprobe vboxdrv 2>/dev/null || warn "Unable to load vboxdrv module. Reboot may be required."
    ${SUDO} systemctl restart virtualbox 2>/dev/null || warn "VirtualBox service restart skipped or unsupported on this system."
    install_packages "virtualbox-guest-additions-iso"
    success "VirtualBox installation completed."
}

install_google_chrome() {
    log "Installing Google Chrome..."
    local chrome_deb="/tmp/google-chrome-stable.deb"
    local chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

    download_file "${chrome_url}" "${chrome_deb}"

    if ! ${SUDO} dpkg -i "${chrome_deb}" >/tmp/chrome-install.log 2>&1; then
        warn "dpkg install reported errors; attempting dependency fix..."
        ${SUDO} apt-get install -f -y --no-install-recommends || fail "Unable to resolve Chrome dependencies."
    fi

    rm -f "${chrome_deb}"
    success "Google Chrome installation completed."
}

install_obs() {
    log "Installing OBS Studio..."
    install_packages "flatpak"

    if ! flatpak remote-list | grep -q "flathub"; then
        ${SUDO} flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
            || warn "Failed to add Flathub remote. Continuing..."
    fi

    flatpak install -y flathub com.obsproject.Studio \
        || fail "Failed to install OBS Studio via Flatpak."
    success "OBS Studio installation completed."
}

main() {
    echo
    echo "=============================================="
    echo "  Debian/Ubuntu/Kali Linux Tool Installer"
    echo "=============================================="
    echo

    require_root_or_sudo
    detect_distro
    ensure_apt_available

    log "Detected OS: ${DISTRO_NAME} (${DISTRO_ID} ${VERSION_ID})"

    apt_update

    # Common essentials
    install_packages "wget" "curl" "ca-certificates" "gnupg" "software-properties-common"

    # 1. zram-tools
    install_packages "zram-tools"
    configure_zram

    # 2. VS Code
    install_vscode

    # 3. VirtualBox
    install_virtualbox

    # 4. Google Chrome
    install_google_chrome

    # 5. OBS Studio
    install_obs

    echo
    success "All requested software installation steps completed successfully."
    echo
    echo "Important:"
    echo "  - Reboot is intentionally not performed automatically."
    echo "  - Please reboot manually when you're ready."
    echo
    echo "Example:"
    echo "  sudo reboot"
    echo
}

main "$@"
