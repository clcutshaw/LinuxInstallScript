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

            # Basic validation
            if [[ ! "$newhost" =~ ^[a-zA-Z0-9-]+$ ]]; then
                echo "Invalid hostname. Skipping hostname change."
                return
            fi

            echo "Setting hostname to '$newhost'..."
            sudo hostnamectl set-hostname "$newhost"

            echo "Hostname changed successfully."
            ;;
        *)
            echo "Hostname unchanged."
            ;;
    esac
}

issurface () {
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

########################################
# Third-party GitHub apps
########################################

install_third_party_apps () {

    install_from_github_deb () {
        local PKG="$1"
        local REPO="$2"
        local REGEX="$3"

        INSTALLED=$(get_installed_version "$PKG")

        URL=$(curl -s "$REPO/releases/latest" | grep -Eo "$REGEX" | head -n 1)
        [[ -z "$URL" ]] && echo "Failed to find $PKG" && return

        VERSION=$(basename "$URL" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1)

        if [[ -n "$INSTALLED" && "$INSTALLED" == "$VERSION"* ]]; then
            echo "$PKG already up to date ($INSTALLED)"
            return
        fi

        echo "Installing $PKG ($VERSION)"
        TMPDIR=$(mktemp -d)
        wget -qO "$TMPDIR/$PKG.deb" "$URL"
        sudo apt install -y "$TMPDIR/$PKG.deb"
        rm -rf "$TMPDIR"
    }

    echo "Installing third-party applications..."

    install_from_github_deb "ipscan" \
        "https://github.com/angryip/ipscan" \
        'https://[^"]+_amd64\.deb'

    install_from_github_deb "libation" \
        "https://github.com/rmcrackan/Libation" \
        'https://[^"]+_amd64\.deb'

    install_from_github_deb "github-desktop" \
        "https://github.com/desktop/desktop" \
        'https://[^"]+amd64\.deb'
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
# Software Installation
# =========================

sudo apt update
sudo apt upgrade -y
sudo apt install nala -y
sudo nala update
sudo nala upgrade -y
sudo nala install -y firefox-esr 
sudo nala install -y cpu-x 
sudo nala install -y hardinfo 
sudo nala install -y vim
sudo nala install -y htop
sudo nala install -y btop 
sudo nala install -y vlc
sudo nala install -y thunderbird 
sudo nala install -y libreoffice
sudo nala install -y handbrake
sudo nala install -y flameshot
sudo nala install -y klavaro
sudo nala install -y mirage
sudo nala install -y remmina
sudo nala install -y putty
sudo nala install -y snapd
sudo snap install snap-store
sudo snap install discord
sudo snap install signal-desktop
sudo snap install bitwarden
sudo snap install termius-app
sudo snap install barrier-kvm
sudo snap install todoist
sudo snap install steam
sudo snap install okular
sudo snap install rpi-imager
sudo snap install cura-slicer
sudo snap install notepad-plus-plus
sudo snap install apple-music-for-linux
sudo snap install audible-for-linux
sudo snap install code --classic
sudo snap install powershell --classic
sudo snap install sublime-text --classic

sudo apt autoclean

echo "Installation complete. System will shut down."

sudo shutdown -h +1
sleep 8
sudo rm -- "$0"
