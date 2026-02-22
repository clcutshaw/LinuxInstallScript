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

kaliinstall () { # Function for repositories for Kali Install 
    add_apt_repo() {
        # Required arguments
        local repo_name="$1"     # short name, e.g. debian-trixie
        local repo_url="$2"      # e.g. http://deb.debian.org/debian
        local distro="$3"        # e.g. trixie
        local components="$4"   # e.g. main contrib non-free
    
        # Optional arguments
        local key_url="$5"       # empty if key already exists
        local pin_priority="$6" # empty to disable pinning (e.g. 100)
    
        local list_file="/etc/apt/sources.list.d/${repo_name}.list"
        local keyring="/usr/share/keyrings/${repo_name}-archive-keyring.gpg"
        local pin_file="/etc/apt/preferences.d/${repo_name}"
    
        echo "[*] Configuring APT repository: ${repo_name}"
    
        # --- Signing key (optional) ---
        if [[ -n "$key_url" ]]; then
            if [[ ! -f "$keyring" ]]; then
                echo "  - Installing signing key"
                curl -fsSL "$key_url" \
                    | gpg --dearmor \
                    | tee "$keyring" > /dev/null
            else
                echo "  - Signing key already present"
            fi
        fi
    
        # --- Repository file ---
        if [[ ! -f "$list_file" ]]; then
            echo "  - Adding repository source"
            if [[ -n "$key_url" ]]; then
                echo "deb [signed-by=$keyring] $repo_url $distro $components" \
                    | tee "$list_file" > /dev/null
            else
                echo "deb $repo_url $distro $components" \
                    | tee "$list_file" > /dev/null
            fi
        else
            echo "  - Repository already exists"
        fi
    
        # --- APT pinning (optional, recommended for Kali + Debian mixing) ---
        if [[ -n "$pin_priority" ]]; then
            if [[ ! -f "$pin_file" ]]; then
                echo "  - Adding APT pin (priority: $pin_priority)"
                cat <<EOF | tee "$pin_file" > /dev/null
    Package: *
    Pin: release n=$distro
    Pin-Priority: $pin_priority
    EOF
            else
                echo "  - Pinning already configured"
            fi
        fi
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

issurface () { # Determining if device is a Surface device
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

# =========================
# Begin Execution
# =========================

interactiveyn

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
