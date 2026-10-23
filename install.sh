#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

LOG_PREFIX="[INSTALL]"
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
INIT_SYSTEM="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]' || echo unknown)"

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

usage() {
    cat <<'EOF'
Usage: install.sh [options]

This installer is designed ONLY for Kali Linux running XFCE, GNOME, or KDE Plasma.

Options:
  --skip-zram         Skip zram configuration
  --skip-vscode       Skip VS Code installation
  --skip-virtualbox   Skip VirtualBox installation
  --skip-chrome       Skip Google Chrome installation
  --skip-obs          Skip OBS Studio installation
  --help              Show this help
EOF
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
        VERSION_CODENAME="${VERSION_CODENAME:-unknown}"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
        VERSION_ID="unknown"
        VERSION_CODENAME="unknown"
    fi
}

detect_desktop_environment() {
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        DE_NAME="${XDG_CURRENT_DESKTOP}"
    elif [ -n "${DESKTOP_SESSION:-}" ]; then
        DE_NAME="${DESKTOP_SESSION}"
    else
        DE_NAME="unknown"
    fi

    case "${DE_NAME,,}" in
        xfce|xfce4|xfce-session)
            DE_NAME="XFCE"
            ;;
        gnome|gnome-shell)
            DE_NAME="GNOME"
            ;;
        plasma|kde|plasma5|plasma6)
            DE_NAME="KDE Plasma"
            ;;
        *)
            DE_NAME="unsupported"
            ;;
    esac
}

is_supported_distro() {
    [ "${DISTRO_ID}" = "kali" ]
}

is_supported_desktop() {
    [ "${DE_NAME}" = "XFCE" ] || [ "${DE_NAME}" = "GNOME" ] || [ "${DE_NAME}" = "KDE Plasma" ]
}

is_package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

apt_package_exists() {
    apt-cache policy "$1" 2>/dev/null | grep -q "Candidate:" || apt-cache search --names-only "$1" 2>/dev/null | grep -qi "^${1}$"
}

install_package_if_available() {
    local pkg="$1"

    if is_package_installed "${pkg}"; then
        success "Package already installed, skipping: ${pkg}"
        return 0
    fi

    if ! apt_package_exists "${pkg}"; then
        warn "Package not available in this Kali repository: ${pkg}. Skipping."
        return 0
    fi

    install_packages "${pkg}"
}

ensure_apt_available() {
    if ! command -v apt-get >/dev/null 2>&1; then
        fail "This script requires apt-get on Kali Linux."
    fi
}

apt_update() {
    log "Updating package lists..."

    if [ -n "${SUDO}" ]; then
        ${SUDO} apt-get update -qq || fail "apt-get update failed."
    else
        apt-get update -qq || fail "apt-get update failed."
    fi
}

install_packages() {
    local packages=("$@")
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    for pkg in "${packages[@]}"; do
        if is_package_installed "${pkg}"; then
            success "Package already installed, skipping: ${pkg}"
            continue
        fi

        log "Installing packages: ${pkg}"
        break
    done

    if [ -n "${SUDO}" ]; then
        ${SUDO} apt-get install -y --no-install-recommends "${packages[@]}" || fail "Failed to install required packages: ${packages[*]}"
    else
        apt-get install -y --no-install-recommends "${packages[@]}" || fail "Failed to install required packages: ${packages[*]}"
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    log "Downloading: ${url}"

    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 --output "${output}" "${url}" || fail "Download failed: ${url}"
    else
        wget -O "${output}" "${url}" || fail "Download failed: ${url}"
    fi
}

add_microsoft_repo() {
    log "Configuring Microsoft repository for VS Code..."
    mkdir -p /etc/apt/keyrings

    if [ ! -f /etc/apt/keyrings/microsoft.gpg ]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /etc/apt/keyrings/microsoft.gpg
    fi

    local repo_file="/etc/apt/sources.list.d/vscode.list"
    if [ ! -f "${repo_file}" ]; then
        echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > "${repo_file}"
    fi

    apt_update
}

add_virtualbox_repo() {
    log "Configuring VirtualBox repository..."
    mkdir -p /etc/apt/keyrings

    if [ ! -f /etc/apt/keyrings/oracle_vbox_2016.gpg ]; then
        curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor --yes -o /etc/apt/keyrings/oracle_vbox_2016.gpg
    fi

    local repo_file="/etc/apt/sources.list.d/virtualbox.list"
    if [ ! -f "${repo_file}" ]; then
        echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/oracle_vbox_2016.gpg] https://download.virtualbox.org/virtualbox/debian ${VERSION_CODENAME} contrib" > "${repo_file}"
    fi

    apt_update
}

zram_already_active() {
    if command -v zramctl >/dev/null 2>&1; then
        zramctl 2>/dev/null | grep -q 'zram' && return 0
    fi
    if swapon --show 2>/dev/null | grep -q '/dev/zram'; then
        return 0
    fi
    if [ -f /etc/default/zramswap ] && grep -q '^ALGO=zstd' /etc/default/zramswap && grep -q '^PERCENT=50' /etc/default/zramswap; then
        return 0
    fi
    return 1
}

configure_zram() {
    log "Configuring zram..."

    if zram_already_active; then
        success "zram is already configured and active. Skipping zram reconfiguration."
        return 0
    fi

    if ! command -v zramctl >/dev/null 2>&1; then
        warn "zramctl not found; zram-tools may still install successfully."
    fi

    install_package_if_available "zram-tools"

    local zram_conf="/etc/default/zramswap"
    if [ ! -f "${zram_conf}" ]; then
        printf 'ALGO=zstd\nPERCENT=50\n' | tee "${zram_conf}" >/dev/null
    else
        if ! grep -Eq '^[[:space:]]*ALGO[[:space:]]*=' "${zram_conf}" || ! grep -Eq 'ALGO=.*zstd' "${zram_conf}"; then
            echo "ALGO=zstd" >> "${zram_conf}"
        fi
        if ! grep -Eq '^[[:space:]]*PERCENT[[:space:]]*=' "${zram_conf}"; then
            echo "PERCENT=50" >> "${zram_conf}"
        fi
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if [ -n "${SUDO}" ]; then
            ${SUDO} systemctl daemon-reload >/dev/null 2>&1 || true
            ${SUDO} systemctl enable --now zramswap >/dev/null 2>&1 || warn "zramswap service could not be enabled on this system."
        else
            systemctl daemon-reload >/dev/null 2>&1 || true
            systemctl enable --now zramswap >/dev/null 2>&1 || warn "zramswap service could not be enabled on this system."
        fi
    else
        warn "Systemd was not detected. zram config has been written, but service activation was skipped."
    fi

    swapon --show 2>/dev/null || true
    zramctl 2>/dev/null || true
    success "zram configuration applied."
}

install_vscode() {
    log "Installing Visual Studio Code..."

    if command -v code >/dev/null 2>&1; then
        success "VS Code is already installed. Skipping."
        return 0
    fi

    add_microsoft_repo
    install_package_if_available "code"
    success "VS Code installation completed."
}

install_virtualbox() {
    log "Installing VirtualBox full stack..."

    if command -v virtualbox >/dev/null 2>&1 || dpkg -s virtualbox >/dev/null 2>&1; then
        success "VirtualBox is already installed. Skipping base package."
    else
        install_package_if_available "build-essential"
        install_package_if_available "dkms"
        install_package_if_available "linux-headers-$(uname -r)"
        install_package_if_available "wget"
        install_package_if_available "curl"
        install_package_if_available "gnupg"

        add_virtualbox_repo

        if [ -n "${SUDO}" ]; then
            echo "virtualbox-ext-pack virtualbox-ext-pack/license select true" | ${SUDO} debconf-set-selections 2>/dev/null || true
            ${SUDO} apt-get install -y --no-install-recommends virtualbox virtualbox-ext-pack || warn "VirtualBox package or extension pack could not be installed from the configured repo."
        else
            echo "virtualbox-ext-pack virtualbox-ext-pack/license select true" | debconf-set-selections 2>/dev/null || true
            apt-get install -y --no-install-recommends virtualbox virtualbox-ext-pack || warn "VirtualBox package or extension pack could not be installed from the configured repo."
        fi
    fi

    if ! is_package_installed "virtualbox-guest-additions-iso"; then
        install_package_if_available "virtualbox-guest-additions-iso"
    else
        success "VirtualBox Guest Additions ISO already installed. Skipping."
    fi

    if getent group vboxusers >/dev/null 2>&1; then
        local current_user="${USER:-$(whoami)}"
        if ! id -nG "${current_user}" | tr ' ' '\n' | grep -qx "vboxusers"; then
            if [ -n "${SUDO}" ]; then
                ${SUDO} usermod -aG vboxusers "${current_user}" || warn "Could not add ${current_user} to vboxusers."
            else
                usermod -aG vboxusers "${current_user}" || warn "Could not add ${current_user} to vboxusers."
            fi
        fi
    else
        if [ -n "${SUDO}" ]; then
            ${SUDO} groupadd -f vboxusers
        else
            groupadd -f vboxusers
        fi
    fi

    if [ -n "${SUDO}" ]; then
        ${SUDO} modprobe vboxdrv >/dev/null 2>&1 || warn "Unable to load the vboxdrv kernel module; a reboot may be required."
    else
        modprobe vboxdrv >/dev/null 2>&1 || warn "Unable to load the vboxdrv kernel module; a reboot may be required."
    fi

    success "VirtualBox full stack installation completed."
}

install_google_chrome() {
    log "Installing Google Chrome..."

    if command -v google-chrome >/dev/null 2>&1 || dpkg -s google-chrome-stable >/dev/null 2>&1; then
        success "Google Chrome is already installed. Skipping."
        return 0
    fi

    if [ "${ARCH}" != "amd64" ]; then
        fail "Google Chrome installer currently supports amd64 architecture only. Detected: ${ARCH}"
    fi

    local chrome_deb="/tmp/google-chrome-stable.deb"
    local chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

    download_file "${chrome_url}" "${chrome_deb}"

    if [ -n "${SUDO}" ]; then
        ${SUDO} apt-get install -y --no-install-recommends "${chrome_deb}" || {
            warn "Chrome package install reported an issue; fixing dependencies..."
            ${SUDO} apt-get install -f -y --no-install-recommends || fail "Unable to resolve Chrome dependencies."
        }
    else
        apt-get install -y --no-install-recommends "${chrome_deb}" || {
            warn "Chrome package install reported an issue; fixing dependencies..."
            apt-get install -f -y --no-install-recommends || fail "Unable to resolve Chrome dependencies."
        }
    fi

    rm -f "${chrome_deb}"
    success "Google Chrome installation completed."
}

install_obs() {
    log "Installing OBS Studio..."

    if flatpak list --installed 2>/dev/null | grep -qi "com.obsproject.Studio"; then
        success "OBS Studio is already installed. Skipping."
        return 0
    fi

    if ! command -v flatpak >/dev/null 2>&1; then
        install_package_if_available "flatpak"
    fi

    if command -v flatpak >/dev/null 2>&1; then
        if ! flatpak remote-list 2>/dev/null | grep -q "flathub"; then
            if [ -n "${SUDO}" ]; then
                ${SUDO} flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || warn "Failed to add Flathub remote. Continuing..."
            else
                flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || warn "Failed to add Flathub remote. Continuing..."
            fi
        fi

        flatpak install -y flathub com.obsproject.Studio || fail "Failed to install OBS Studio via Flatpak."
        success "OBS Studio installation completed."
    else
        warn "Flatpak is not available on this Kali system; skipping OBS Studio installation."
    fi
}

prepare_system() {
    log "Preparing system packages..."

    for pkg in wget curl ca-certificates gnupg lsb-release; do
        install_package_if_available "${pkg}"
    done

    install_package_if_available "software-properties-common"
    install_package_if_available "apt-transport-https"
}

main() {
    local install_zram=true
    local install_vscode=true
    local install_virtualbox=true
    local install_chrome=true
    local install_obs=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-zram)
                install_zram=false
                ;;
            --skip-vscode)
                install_vscode=false
                ;;
            --skip-virtualbox)
                install_virtualbox=false
                ;;
            --skip-chrome)
                install_chrome=false
                ;;
            --skip-obs)
                install_obs=false
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                fail "Unknown option: $1"
                ;;
        esac
        shift
    done

    echo
    echo "=============================================="
    echo "  Kali Linux Installer for XFCE / GNOME / KDE"
    echo "=============================================="
    echo

    require_root_or_sudo
    detect_distro
    detect_desktop_environment
    ensure_apt_available

    if ! is_supported_distro; then
        fail "This installer is only for Kali Linux. Detected: ${DISTRO_NAME} (${DISTRO_ID})."
    fi

    if ! is_supported_desktop; then
        fail "This installer supports only XFCE, GNOME, and KDE Plasma. Detected desktop: ${DE_NAME}."
    fi

    log "Detected OS: ${DISTRO_NAME} (${DISTRO_ID} ${VERSION_ID})"
    log "Detected desktop environment: ${DE_NAME}"
    log "Detected init system: ${INIT_SYSTEM}"

    prepare_system
    apt_update

    if [ "${install_zram}" = true ]; then
        configure_zram
    else
        warn "Skipping zram configuration because --skip-zram was used."
    fi

    if [ "${install_vscode}" = true ]; then
        install_vscode
    else
        warn "Skipping VS Code because --skip-vscode was used."
    fi

    if [ "${install_virtualbox}" = true ]; then
        install_virtualbox
    else
        warn "Skipping VirtualBox because --skip-virtualbox was used."
    fi

    if [ "${install_chrome}" = true ]; then
        install_google_chrome
    else
        warn "Skipping Google Chrome because --skip-chrome was used."
    fi

    if [ "${install_obs}" = true ]; then
        install_obs
    else
        warn "Skipping OBS Studio because --skip-obs was used."
    fi

    echo
    success "All selected software installation steps completed successfully."
    echo
    echo "Important:"
    echo "  - This installer is restricted to Kali Linux only."
    echo "  - Reboot is intentionally not executed automatically."
    echo "  - Please reboot manually when appropriate."
    echo
    echo "Example:"
    echo "  sudo reboot"
    echo
}

main "$@"
