#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

REPO_URL="https://github.com/rahibnahiyan-cyber/My-Personal"
LOG_PREFIX="[INSTALL]"
LOG_FILE="/var/log/kali-setup.log"
PROFILE="full"
DRY_RUN=false
VERIFY_ONLY=false

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
INIT_SYSTEM="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]' || echo unknown)"

INSTALL_SUCCESS_COUNT=0
INSTALL_SKIP_COUNT=0
INSTALL_FAIL_COUNT=0
declare -a FAILED_TASKS=()
declare -a SKIPPED_TASKS=()

mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null || true
: > "${LOG_FILE}" 2>/dev/null || true

cleanup() {
    rm -f /tmp/google-chrome-stable.deb 2>/dev/null || true
    rm -f /tmp/virtualbox-*.iso 2>/dev/null || true
    rm -f /tmp/obs-flatpak.* 2>/dev/null || true
}
trap cleanup EXIT

log() {
    local msg="$1"
    echo -e "${BLUE}${LOG_PREFIX} ${msg}${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${LOG_PREFIX} ${msg}" >> "${LOG_FILE}"
}

success() {
    local msg="$1"
    echo -e "${GREEN}${LOG_PREFIX} ${msg}${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${LOG_PREFIX} ${msg}" >> "${LOG_FILE}"
    INSTALL_SUCCESS_COUNT=$((INSTALL_SUCCESS_COUNT + 1))
}

warn() {
    local msg="$1"
    echo -e "${YELLOW}${LOG_PREFIX} WARNING: ${msg}${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${LOG_PREFIX} WARNING: ${msg}" >> "${LOG_FILE}"
}

fail() {
    local msg="$1"
    echo -e "${RED}${LOG_PREFIX} ERROR: ${msg}${NC}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${LOG_PREFIX} ERROR: ${msg}" >> "${LOG_FILE}"
    FAILED_TASKS+=("${msg}")
    INSTALL_FAIL_COUNT=$((INSTALL_FAIL_COUNT + 1))
    exit 1
}

skip_task() {
    local task="$1"
    SKIPPED_TASKS+=("${task}")
    INSTALL_SKIP_COUNT=$((INSTALL_SKIP_COUNT + 1))
}

show_running_processes() {
    local label="${1:-Current}"
    echo
    echo "=============================================="
    echo "  Running Processes: ${label}"
    echo "=============================================="
    ps -eo pid,ppid,comm,%cpu,%mem,etime --sort=-%cpu 2>/dev/null | head -n 20 || echo "No process information available."
    echo
}

usage() {
    cat <<EOF
Usage: install.sh [options]

This installer is designed ONLY for Kali Linux running XFCE, GNOME, or KDE Plasma.
Repository: ${REPO_URL}

Options:
  --skip-zram         Skip zram configuration
  --skip-vscode       Skip VS Code installation
  --skip-virtualbox   Skip VirtualBox installation
  --skip-chrome       Skip Google Chrome installation
  --skip-obs          Skip OBS Studio installation
  --skip-kdenlive     Skip Kdenlive installation
  --skip-libreoffice  Skip LibreOffice installation
  --verify            Run verification checks only
  --dry-run           Show what would be installed without executing
  --profile <name>   Choose profile: full, minimal, media, cyber
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

repo_sync() {
    if ! command -v git >/dev/null 2>&1; then
        warn "git is not installed; skipping repository sync."
        skip_task "repo_sync"
        return 0
    fi

    if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
        warn "The script is not running inside a git repository; skipping repository sync."
        skip_task "repo_sync"
        return 0
    fi

    local repo_root
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
    if [ -z "${repo_root}" ]; then
        warn "Unable to determine repository root; skipping repository sync."
        skip_task "repo_sync"
        return 0
    fi

    if ! git -C "${repo_root}" remote get-url origin >/dev/null 2>&1; then
        warn "No git remote 'origin' found; skipping repository sync."
        skip_task "repo_sync"
        return 0
    fi

    if [ -n "$(git -C "${repo_root}" status --porcelain 2>/dev/null)" ]; then
        warn "Local changes detected; skipping automatic repository pull to avoid overwriting your work."
        skip_task "repo_sync"
        return 0
    fi

    log "Checking repository updates in: ${repo_root}"
    show_running_processes "Before repo sync"

    git -C "${repo_root}" fetch --all --prune --quiet || {
        warn "git fetch failed; continuing without repo update."
        skip_task "repo_sync"
        return 0
    }

    if git -C "${repo_root}" merge --ff-only @{u} >/dev/null 2>&1; then
        success "Repository sync completed successfully."
    else
        warn "Fast-forward merge was not possible. Continuing with the current local version."
        skip_task "repo_sync"
    fi

    show_running_processes "After repo sync"
}

install_package_if_available() {
    local pkg="$1"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install package: ${pkg}"
        return 0
    fi

    if is_package_installed "${pkg}"; then
        success "Package already installed, skipping: ${pkg}"
        return 0
    fi

    if ! apt_package_exists "${pkg}"; then
        warn "Package not available in this Kali repository: ${pkg}. Skipping."
        skip_task "install:${pkg}"
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
    show_running_processes "Before apt update"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would run: apt-get update -qq"
        show_running_processes "After apt update (dry-run)"
        return 0
    fi

    if [ -n "${SUDO}" ]; then
        ${SUDO} apt-get update -qq || fail "apt-get update failed."
    else
        apt-get update -qq || fail "apt-get update failed."
    fi

    show_running_processes "After apt update"
}

full_system_upgrade() {
    log "Running full system upgrade..."
    show_running_processes "Before full upgrade"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would run: apt-get full-upgrade -y --no-install-recommends"
        show_running_processes "After full upgrade (dry-run)"
        return 0
    fi

    if [ -n "${SUDO}" ]; then
        ${SUDO} apt-get update -qq || fail "apt-get update failed."
        ${SUDO} apt-get full-upgrade -y --no-install-recommends || fail "apt-get full-upgrade failed."
    else
        apt-get update -qq || fail "apt-get update failed."
        apt-get full-upgrade -y --no-install-recommends || fail "apt-get full-upgrade failed."
    fi

    show_running_processes "After full upgrade"
    success "Full system upgrade completed."
}

install_packages() {
    local packages=("$@")
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install: ${packages[*]}"
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

    show_running_processes "During package install: ${packages[*]}"

    if [ -n "${SUDO}" ]; then
        ${SUDO} apt-get install -y --no-install-recommends "${packages[@]}" || fail "Failed to install required packages: ${packages[*]}"
    else
        apt-get install -y --no-install-recommends "${packages[@]}" || fail "Failed to install required packages: ${packages[*]}"
    fi

    show_running_processes "After package install: ${packages[*]}"
}

download_file() {
    local url="$1"
    local output="$2"
    log "Downloading: ${url}"
    show_running_processes "Downloading ${url}"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would download: ${url} to ${output}"
        show_running_processes "Download finished: ${url} (dry-run)"
        return 0
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 --output "${output}" "${url}" || fail "Download failed: ${url}"
    else
        wget -O "${output}" "${url}" || fail "Download failed: ${url}"
    fi

    show_running_processes "Download finished: ${url}"
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
    show_running_processes "Before zram configuration"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would configure zram-tools and zramswap"
        show_running_processes "zram configuration (dry-run)"
        return 0
    fi

    if zram_already_active; then
        success "zram is already configured and active. Skipping zram reconfiguration."
        show_running_processes "zram already active"
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
    show_running_processes "After zram configuration"
    success "zram configuration applied."
}

install_vscode() {
    log "Installing Visual Studio Code..."
    show_running_processes "Before VS Code install"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install VS Code"
        show_running_processes "VS Code install (dry-run)"
        return 0
    fi

    if command -v code >/dev/null 2>&1; then
        success "VS Code is already installed. Skipping."
        show_running_processes "VS Code already installed"
        return 0
    fi

    add_microsoft_repo
    install_package_if_available "code"
    show_running_processes "After VS Code install"
    success "VS Code installation completed."
}

install_virtualbox() {
    log "Installing VirtualBox full stack..."
    show_running_processes "Before VirtualBox install"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install VirtualBox and guest additions"
        show_running_processes "VirtualBox install (dry-run)"
        return 0
    fi

    if command -v virtualbox >/dev/null 2>&1 || dpkg -s virtualbox >/dev/null 2>&1; then
        success "VirtualBox is already installed. Skipping base package."
        show_running_processes "VirtualBox already installed"
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

    show_running_processes "After VirtualBox install"
    success "VirtualBox full stack installation completed."
}

install_google_chrome() {
    log "Installing Google Chrome..."
    show_running_processes "Before Chrome install"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install Google Chrome"
        show_running_processes "Chrome install (dry-run)"
        return 0
    fi

    if command -v google-chrome >/dev/null 2>&1 || dpkg -s google-chrome-stable >/dev/null 2>&1; then
        success "Google Chrome is already installed. Skipping."
        show_running_processes "Chrome already installed"
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
    show_running_processes "After Chrome install"
    success "Google Chrome installation completed."
}

install_obs() {
    log "Installing OBS Studio..."
    show_running_processes "Before OBS install"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install OBS Studio via Flatpak"
        show_running_processes "OBS install (dry-run)"
        return 0
    fi

    if flatpak list --installed 2>/dev/null | grep -qi "com.obsproject.Studio"; then
        success "OBS Studio is already installed. Skipping."
        show_running_processes "OBS already installed"
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
        show_running_processes "After OBS install"
        success "OBS Studio installation completed."
    else
        warn "Flatpak is not available on this Kali system; skipping OBS Studio installation."
    fi
}

install_kdenlive() {
    log "Installing Kdenlive..."
    show_running_processes "Before Kdenlive install"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install Kdenlive"
        show_running_processes "Kdenlive install (dry-run)"
        return 0
    fi

    if is_package_installed "kdenlive"; then
        success "Kdenlive is already installed. Skipping."
        show_running_processes "Kdenlive already installed"
        return 0
    fi

    install_package_if_available "kdenlive"
    show_running_processes "After Kdenlive install"
    success "Kdenlive installation completed."
}

install_libreoffice() {
    log "Installing LibreOffice..."
    show_running_processes "Before LibreOffice install"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install LibreOffice"
        show_running_processes "LibreOffice install (dry-run)"
        return 0
    fi

    if is_package_installed "libreoffice"; then
        success "LibreOffice is already installed. Skipping."
        show_running_processes "LibreOffice already installed"
        return 0
    fi

    install_package_if_available "libreoffice"
    show_running_processes "After LibreOffice install"
    success "LibreOffice installation completed."
}

prepare_system() {
    log "Preparing system packages..."
    show_running_processes "Before system prep"

    if [ "${DRY_RUN}" = true ]; then
        log "[DRY-RUN] Would install: wget curl ca-certificates gnupg lsb-release software-properties-common apt-transport-https"
        show_running_processes "After system prep (dry-run)"
        return 0
    fi

    for pkg in wget curl ca-certificates gnupg lsb-release; do
        install_package_if_available "${pkg}"
    done

    install_package_if_available "software-properties-common"
    install_package_if_available "apt-transport-https"

    show_running_processes "After system prep"
}

verify_installation() {
    echo
    echo "=============================================="
    echo "  Verification Checks"
    echo "=============================================="
    echo

    local ok_count=0
    local total=0

    verify_item() {
        local label="$1"
        local check_cmd="$2"
        total=$((total + 1))
        if eval "${check_cmd}" >/dev/null 2>&1; then
            echo "[OK] ${label}"
            ok_count=$((ok_count + 1))
        else
            echo "[MISSING] ${label}"
        fi
    }

    verify_item "VS Code" "command -v code"
    verify_item "Google Chrome" "command -v google-chrome"
    verify_item "VirtualBox" "command -v VBoxManage"
    verify_item "OBS Studio" "flatpak list --installed 2>/dev/null | grep -qi 'com.obsproject.Studio'"
    verify_item "zramctl" "command -v zramctl"
    verify_item "Kdenlive" "command -v kdenlive"
    verify_item "LibreOffice" "command -v libreoffice"

    echo
    echo "Verification summary: ${ok_count}/${total} checks passed."
    show_running_processes "Verification final state"
}

show_summary() {
    echo
    echo "=============================================="
    echo "  Install Summary"
    echo "=============================================="
    echo
    echo "Status: ${INSTALL_SUCCESS_COUNT} success, ${INSTALL_SKIP_COUNT} skipped, ${INSTALL_FAIL_COUNT} failed"
    echo "Log file: ${LOG_FILE}"

    if [ ${#SKIPPED_TASKS[@]} -gt 0 ]; then
        echo
        echo "Skipped tasks:"
        for task in "${SKIPPED_TASKS[@]}"; do
            echo "  - ${task}"
        done
    fi

    if [ ${#FAILED_TASKS[@]} -gt 0 ]; then
        echo
        echo "Failed tasks:"
        for task in "${FAILED_TASKS[@]}"; do
            echo "  - ${task}"
        done
    fi

    echo
}

process_profile() {
    case "${PROFILE}" in
        full)
            return 0
            ;;
        minimal)
            # only essential items; skip heavy apps
            SKIP_ZRAM=false
            SKIP_VSCODE=false
            SKIP_VIRTUALBOX=true
            SKIP_CHROME=false
            SKIP_OBS=true
            SKIP_KDENLIVE=true
            SKIP_LIBREOFFICE=true
            ;;
        media)
            SKIP_ZRAM=false
            SKIP_VSCODE=false
            SKIP_VIRTUALBOX=false
            SKIP_CHROME=false
            SKIP_OBS=false
            SKIP_KDENLIVE=false
            SKIP_LIBREOFFICE=true
            ;;
        cyber)
            SKIP_ZRAM=false
            SKIP_VSCODE=false
            SKIP_VIRTUALBOX=false
            SKIP_CHROME=true
            SKIP_OBS=true
            SKIP_KDENLIVE=true
            SKIP_LIBREOFFICE=true
            ;;
        *)
            fail "Unsupported profile: ${PROFILE}. Use one of: full, minimal, media, cyber."
            ;;
    esac
}

main() {
    local install_zram=true
    local install_vscode=true
    local install_virtualbox=true
    local install_chrome=true
    local install_obs=true
    local install_kdenlive_flag=true
    local install_libreoffice_flag=true

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
            --skip-kdenlive)
                install_kdenlive_flag=false
                ;;
            --skip-libreoffice)
                install_libreoffice_flag=false
                ;;
            --verify)
                VERIFY_ONLY=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --profile)
                if [ $# -lt 2 ]; then
                    fail "--profile requires a value."
                fi
                PROFILE="$2"
                shift
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

    if [ "${VERIFY_ONLY}" = true ]; then
        require_root_or_sudo
        detect_distro
        detect_desktop_environment
        show_running_processes "Verification mode startup"
        verify_installation
        exit 0
    fi

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
    show_running_processes "Startup state"

    process_profile

    if [ "${PROFILE}" != "full" ] || [ "${DRY_RUN}" = true ]; then
        log "Selected profile: ${PROFILE}"
    fi

    if [ "${PROFILE}" = "full" ] && [ "${DRY_RUN}" = false ]; then
        repo_sync
    else
        warn "Skipping repo sync because dry-run or non-full profile is active."
    fi

    prepare_system
    apt_update
    full_system_upgrade

    if [ "${install_zram}" = true ] && [ "${SKIP_ZRAM:-false}" != "true" ]; then
        configure_zram
    else
        warn "Skipping zram configuration because --skip-zram was used or the selected profile excludes it."
    fi

    if [ "${install_vscode}" = true ] && [ "${SKIP_VSCODE:-false}" != "true" ]; then
        install_vscode
    else
        warn "Skipping VS Code because --skip-vscode was used or the selected profile excludes it."
    fi

    if [ "${install_virtualbox}" = true ] && [ "${SKIP_VIRTUALBOX:-false}" != "true" ]; then
        install_virtualbox
    else
        warn "Skipping VirtualBox because --skip-virtualbox was used or the selected profile excludes it."
    fi

    if [ "${install_chrome}" = true ] && [ "${SKIP_CHROME:-false}" != "true" ]; then
        install_google_chrome
    else
        warn "Skipping Google Chrome because --skip-chrome was used or the selected profile excludes it."
    fi

    if [ "${install_obs}" = true ] && [ "${SKIP_OBS:-false}" != "true" ]; then
        install_obs
    else
        warn "Skipping OBS Studio because --skip-obs was used or the selected profile excludes it."
    fi

    if [ "${install_kdenlive_flag}" = true ] && [ "${SKIP_KDENLIVE:-false}" != "true" ]; then
        install_kdenlive
    else
        warn "Skipping Kdenlive because --skip-kdenlive was used or the selected profile excludes it."
    fi

    if [ "${install_libreoffice_flag}" = true ] && [ "${SKIP_LIBREOFFICE:-false}" != "true" ]; then
        install_libreoffice
    else
        warn "Skipping LibreOffice because --skip-libreoffice was used or the selected profile excludes it."
    fi

    echo
    success "All selected software installation steps completed successfully."
    show_running_processes "Final installation state"
    verify_installation
    show_summary

    echo
    echo "Repository: ${REPO_URL}"
    echo
    echo "Important:"
    echo "  - This installer is restricted to Kali Linux only."
    echo "  - Reboot is intentionally not executed automatically."
    echo "  - Please reboot manually when appropriate."
    echo "  - Log file: ${LOG_FILE}"
    echo
    echo "Example:"
    echo "  sudo reboot"
    echo
}

main "$@"
