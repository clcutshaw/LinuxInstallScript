#!/bin/bash

# To be run after adding machine local user to sudo group
echo "Welcome User. Beginning installation of your Linux Configuration"

# =========================
# Functions
# =========================

debianinstall () { # Function for KDE install on Debian
    sudo apt install xorg -y
    sudo apt install sddm -y
    sudo systemctl enable sddm
    sudo systemctl set-default graphical.target
    sudo apt install kde-plasma-desktop -y
    sudo apt autoremove --purge konqueror kate kwalletmanager -y
}

interactiveyn () { # Function for y/n user interact
    while true; do
        read -p "Do you want to proceed? [y/n]: " yn
        case $yn in
            [yY]) echo "Proceeding..."; break ;;
            [nN]) echo "Installation cancelled. System will restart.";
                  sudo shutdown -r +1; sleep 8; rm -- "$0"; exit 0 ;;
            *) echo "Invalid response." ;;
        esac
    done
}

changehostname () {
    echo
    echo "Current hostname: $(hostname)"
    echo

    read -p "Do you want to change the hostname? [y/n]: " hn

    case $hn in
        [yY])
            read -p "Enter new hostname (letters, numbers, hyphens only): " newhost

            # Validation
            if [[ ! "$newhost" =~ ^[a-zA-Z0-9-]+$ ]]; then
                echo "Invalid hostname. Skipping hostname change."
                return
            fi

            oldhost=$(hostname)

            echo "Setting hostname to '$newhost'..."
            sudo hostnamectl set-hostname "$newhost"

            # Fix /etc/hosts
            if grep -q "127.0.1.1" /etc/hosts; then
                sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$newhost/" /etc/hosts
            else
                echo -e "127.0.1.1\t$newhost" | sudo tee -a /etc/hosts > /dev/null
            fi

            echo "Hostname updated from '$oldhost' to '$newhost'."
            ;;
        *)
            echo "Hostname unchanged."
            ;;
    esac
}

issurface () { #determining if device is a Surface
    grep -qi "surface" /sys/class/dmi/id/product_name 2>/dev/null
}

hassurfacekernel () { # Determining if device has Surface Kernel
    dpkg -l | grep -q linux-image-surface
}

surfaceinstall () { # Installing Surface Kernel if it does not
    echo "Installing linux-surface kernel (official method)..."

    sudo apt install -y wget gnupg ca-certificates apt-transport-https

    wget -qO - https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
        | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/linux-surface.gpg

    echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" \
        | sudo tee /etc/apt/sources.list.d/linux-surface.list

    sudo apt update

    # iptsd compatibility check
    source /etc/os-release
    SURFACE_PKGS="linux-image-surface linux-headers-surface libwacom-surface"

    if { [ "$ID" = "debian" ] && [ "${VERSION_ID%%.*}" -ge 11 ]; } || \
       { [ "$ID" = "ubuntu" ] && [ "${VERSION_ID%%.*}" -ge 22 ]; }; then
        SURFACE_PKGS="$SURFACE_PKGS iptsd"
    fi

    sudo apt install -y $SURFACE_PKGS
    sudo apt install -y linux-surface-secureboot-mok
    sudo update-grub
}

########################################
# Version helper
########################################

get_installed_version () {
    dpkg-query -W -f='${Version}' "$1" 2>/dev/null || true
}



# =========================
# Default Applications (APT)
# =========================

install_default_apps () {
    echo
    echo "========================================"
    echo " Installing Default Applications"
    echo "========================================"

    # Update package lists and upgrade system
    sudo apt update || return 1
    sudo apt upgrade -y || return 1

    # Default Debian applications
    local APPS=(
        nala
		firefox-esr
        cpu-x
        hardinfo
        vim
        htop
        btop
        vlc
        thunderbird
        libreoffice
        handbrake
        flameshot
        klavaro
        mirage
        remmina
        putty
        gparted
        curl
        kitty
        okular
		f3d
    )

    echo "Installing default applications..."

    if sudo apt install -y "${APPS[@]}"; then
        echo "Default application installation complete."
    else
        echo "ERROR: Default application installation failed."
        return 1
    fi
}

# =========================
# Snap Applications
# =========================

install_snap () {
    echo
    echo "========================================"
    echo " Installing Snap Applications"
    echo "========================================"

    # Install Snap and KDE Discover integration
    if ! sudo nala install -y snapd plasma-discover-backend-snap; then
        echo "ERROR: Failed to install Snap support."
        return 1
    fi

    # Enable the Snap socket
    if ! sudo systemctl enable --now snapd.socket; then
        echo "WARNING: Could not enable snapd.socket."
    fi

    # Install the Snap Store
    local APPS=(
        snap-store
        signal-desktop
        termius-app
        barrier-kvm
        todoist
        steam
        cura-slicer
        notepad-plus-plus
        apple-music-for-linux
        audible-for-linux
    )

    local CLASSIC_APPS=(
        code
        powershell
        sublime-text
    )

    local APP

    for APP in "${APPS[@]}"; do
        echo "Installing Snap: $APP"

        if ! sudo snap install "$APP"; then
            echo "WARNING: Failed to install Snap: $APP"
        fi
    done

    # Applications requiring classic confinement
    for APP in "${CLASSIC_APPS[@]}"; do
        echo "Installing classic Snap: $APP"

        if ! sudo snap install "$APP" --classic; then
            echo "WARNING: Failed to install classic Snap: $APP"
        fi
    done

    echo "Snap application processing complete."
}


# =========================
# Flatpak Applications
# =========================

install_flatpak () {
    echo
    echo "========================================"
    echo " Installing Flatpak Applications"
    echo "========================================"

    # Install Flatpak and KDE Discover integration
    if ! sudo nala install -y flatpak plasma-discover-backend-flatpak; then
        echo "ERROR: Failed to install Flatpak support."
        return 1
    fi

    # Configure the system-wide Flathub repository
    if ! sudo flatpak remote-add --if-not-exists --system \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        echo "ERROR: Failed to configure Flathub."
        return 1
    fi

    # Flatpak application IDs
  local APPS=(
    "com.bambulab.BambuStudio"
    "com.discordapp.Discord"
    "com.bitwarden.desktop"
	"org.speedcrunch.SpeedCrunch"

)

    local APP

    for APP in "${APPS[@]}"; do
        echo "Installing Flatpak: $APP"

        if ! sudo flatpak install --system --assumeyes flathub "$APP"; then
            echo "WARNING: Failed to install Flatpak: $APP"
        fi
    done

    echo "Flatpak application processing complete."
}

########################################
# Third-party GitHub apps
########################################

install_third_party_apps () {

    log () {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    }

    install_from_github_api () {
        local PKG="$1"
        local REPO="$2"
        local ASSET_PATTERN="${3:-amd64.*\.deb$}"

        log "Checking $PKG..."

        local INSTALLED
        INSTALLED=$(get_installed_version "$PKG")

        local API_URL="https://api.github.com/repos/${REPO}/releases/latest"

        local DEB_URL
        DEB_URL=$(
            curl -fsSL "$API_URL" \
            | grep '"browser_download_url"' \
            | cut -d '"' -f 4 \
            | grep -E "$ASSET_PATTERN" \
            | head -n 1
        )

        if [[ -z "$DEB_URL" ]]; then
            log "ERROR: Could not find matching .deb asset for $PKG"
            return 1
        fi

        local TMPDIR
        TMPDIR=$(mktemp -d)

        log "Downloading $PKG..."
        wget -qO "$TMPDIR/$PKG.deb" "$DEB_URL"

        if ! dpkg-deb --info "$TMPDIR/$PKG.deb" >/dev/null 2>&1; then
            log "ERROR: Downloaded file is not a valid deb package."
            rm -rf "$TMPDIR"
            return 1
        fi

        local VERSION
        VERSION=$(dpkg-deb -f "$TMPDIR/$PKG.deb" Version)

        if [[ -n "$INSTALLED" ]]; then
            if dpkg --compare-versions "$INSTALLED" ge "$VERSION"; then
                log "$PKG already up to date ($INSTALLED)"
                rm -rf "$TMPDIR"
                return 0
            fi
        fi

        log "Installing $PKG ($VERSION)..."

        if sudo apt install -y "$TMPDIR/$PKG.deb"; then
            log "$PKG installation complete."
        else
            log "ERROR: Failed to install $PKG"
            rm -rf "$TMPDIR"
            return 1
        fi

        rm -rf "$TMPDIR"
    }

    log "Installing third-party applications..."

    install_from_github_api \
        "ipscan" \
        "angryip/ipscan"

    install_from_github_api \
        "libation" \
        "rmcrackan/Libation"

    install_from_github_api \
        "github-desktop" \
        "shiftkey/desktop" \
        "GitHubDesktop-linux-amd64.*\.deb$"

    install_from_github_api \
        "rpi-imager" \
        "raspberrypi/rpi-imager" \
        "/rpi-imager_[0-9].*_amd64\.deb$"
	    
	install_from_github_api \
        "balena-etcher" \
        "balena-io/etcher" \
        "balena-etcher_[0-9].*_amd64\.deb$"

    log "All third-party applications processed."
}

# =========================
#  Install Mullvad (Stable)
# =========================

install_mullvad_stable () {

    echo "Installing Mullvad VPN (stable release)..."

    local INSTALLED
    INSTALLED=$(dpkg-query -W -f='${Version}' mullvad-vpn 2>/dev/null || true)

    local API_URL="https://api.github.com/repos/mullvad/mullvadvpn-app/releases?per_page=20"

    # Get latest stable Mullvad Linux amd64 release (exclude beta)
    local DEB_URL
    DEB_URL=$(curl -s "$API_URL" \
        | grep '"browser_download_url"' \
        | grep 'MullvadVPN-.*_amd64\.deb' \
        | grep -v 'beta' \
        | head -n 1 \
        | cut -d '"' -f 4)

    if [[ -z "$DEB_URL" ]]; then
        echo "ERROR: Could not find stable Mullvad .deb release."
        return 1
    fi

    local VERSION
    VERSION=$(basename "$DEB_URL" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1)

    if [[ -n "$INSTALLED" && "$INSTALLED" == "$VERSION"* ]]; then
        echo "Mullvad VPN already up to date ($INSTALLED)"
        return 0
    fi

    local TMPDIR
    TMPDIR=$(mktemp -d)

    echo "Downloading Mullvad VPN ($VERSION)..."
    wget -qO "$TMPDIR/mullvad.deb" "$DEB_URL"

    echo "Installing Mullvad VPN..."
    sudo apt install -y "$TMPDIR/mullvad.deb"

    rm -rf "$TMPDIR"

    echo "Mullvad VPN installation complete."
}

# =========================
# Begin Execution
# =========================

interactiveyn

changehostname

sudo apt update
sudo apt upgrade -y

# Determine OS
source /etc/os-release

case $ID in
    debian)
        echo "This machine is running Debian"
        debianinstall
        ;;
    kali)
        echo "This machine is running Kali Linux"
        ;;
    zorin)
        echo "This machine is running Zorin"
        ;;
    *)
        echo "This machine is running $ID"
        ;;
esac

# =========================
# Surface Device Handling
# =========================

# First run: Surface kernel not installed
if issurface && ! hassurfacekernel; then
    surfaceinstall

    echo
    echo "======================================================"
    echo " Microsoft Surface device detected"
    echo
    echo " Secure Boot enrollment is REQUIRED."
    echo
    echo " PLEASE REBOOT THE SYSTEM MANUALLY."
    echo " When prompted, enroll the key using password: surface"
    echo
    echo " After reboot and login, RUN THIS SCRIPT AGAIN."
    echo "======================================================"
    echo

    read -p "Press ENTER to exit the installer now..." _
    exit 0
fi

# Second run: Surface kernel already installed
if issurface && hassurfacekernel; then
    echo "Surface kernel already installed. Continuing setup..."
    uname -a | grep -q surface || echo "WARNING: Not currently booted into surface kernel."
fi

# =========================
# Broadcom Driver Installer
# =========================

BroadcomWifi=$(lspci | grep Netw | grep -o 'BCM[0-9]\+') #searches for Broadcom wifi driver for older Macs, adds non-free and non-free-firmware components if needed.
case $BroadcomWifi in
    BCM4331) # Matches BCM4331
        echo "This machine needs firmware for the Broacdom BCM4331";
	sudo tee /etc/apt/sources.list.d/testlist.list <<EOL
        deb https://deb.debian.org/debian bookworm contrib non-free
EOL
	sudo apt update
	sudo apt install -y firmware-b43-installer;
 	unset BroadcomWifi;
 	;;
  BCM4360) # Matches BCM4360
        echo "This machine needs firmware for the Broacdom BCM4360";
	sudo tee /etc/apt/sources.list.d/testlist.list <<EOL
        deb https://deb.debian.org/debian bookworm contrib non-free
EOL
	sudo apt update
	sudo apt install -y firmware-b43-installer;
 	unset BroadcomWifi;
 	;;
  *) #No Match
   	echo "This Machine does not use a Broadcom WiFi Driver";
    	unset BroadcomWifi;
        ;;
esac


# =========================
# Software Installation
# =========================

#Apps best installed by APT/Nala
install_default_apps || echo "WARNING: Default app installation encountered errors."

#Apps best installed by Snap
install_snap || echo "WARNING: Snap installation encountered errors."

# Apps best installed by Flatpak
install_flatpak || echo "WARNING: Flatpak installation encountered errors."

# Third-party GitHub .deb applications
install_third_party_apps

# Mullvad VPN stable release
install_mullvad_stable

# Clean the APT package cache
sudo apt autoclean

echo "Installation complete. System will shut down."

sudo shutdown -h +1
sleep 8
sudo rm -- "$0"

