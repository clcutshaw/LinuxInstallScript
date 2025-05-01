#!/bin/bash

#To be run after adding machine local user to sudo group
echo "Welcome User. Beginning installation of your Linux Configuration"
#echo “Do you wish to proceed?”

sudo apt update
sudo apt upgrade -y

# This populates the OS Identification Data
source /etc/os-release

debianinstall () { #Function for KDE install on Debian
sudo apt install xorg -y
sudo apt install sddm -y
sudo systemctl enable sddm
sudo systemctl set-default graphical.target
sudo apt install kde-plasma-desktop -y
sudo apt autoremove --purge konqueror -y
sudo apt autoremove --purge kate -y
sudo apt autoremove --purge kwalletmanager -y 
}

case $ID in
  debian) # Matches "debian"
    echo "This machine is running Debian";
    debianinstall;
    sleep 10
    ;; 
  kali) # Matches "arch"
    echo "This machine is running Kali Linux";
    sleep 10;	
    ;;
  zorin) # Matches "zorin"
    echo "This machine is running Zorin";
    sleep 10;
    ;;	 
  *) # This is the default case
    echo "This machine is running $ID";
    sleep 10 
    ;;
esac # ends case statement

sudo apt update
sudo apt upgrade -y
sudo apt install nala -y
sudo nala update
sudo nala upgrade -y
sudo nala install firefox-esr -y
sudo nala install cpu-x -y
sudo nala install hardinfo -y
sudo nala install vim -y
sudo nala install htop -y
sudo nala install btop -y
sudo nala install vlc -y
sudo nala install thunderbird -y
sudo nala install libreoffice -y
sudo nala install handbrake -y
sudo nala install flameshot -y
sudo nala install barrier -y
sudo nala install klavaro -y
sudo nala install snapd -y
sudo snap install discord
sudo snap install bitwarden
sudo snap install todoist
sudo snap install steam
sudo snap install okular
sudo snap install notepad-plus-plus
sudo snap install apple-music-for-linux
sudo snap install audible-for-linux

echo "Installation complete, device will now restart."
#echo “Preparing cryptographic signatures for advance setup. Proceed?”
echo "Installation complete. Media will now self delete. Have a good day."
#sleep 10
sudo shutdown -r +1
sleep 10
rm -- $0


