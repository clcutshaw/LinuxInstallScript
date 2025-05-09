#!/bin/bash

#To be run after adding machine local user to sudo group
echo "Welcome User. Beginning installation of your Linux Configuration"

#Functions for automated install 

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

interactiveyn() { #Function for y/n user interact
while true; do

read -p "Do you want to proceed? [Y/N]" yn

case $yn in 
	[yY]) echo ok, we will proceed;
		break;;
	[nN]) echo Installation cancelled. Media will self delete, computer will restart.;
		sudo shutdown -r +1;
		sleep 8;
		rm -- $0;;
	* ) echo invalid response;;
esac

done
}

interactiveyn

sudo apt update
sudo apt upgrade -y

#Determine OS to select install path 

source /etc/os-release #This populates the OS Identification Data

case $ID in
  debian) # Matches "debian"
    echo "This machine is running Debian";
    debianinstall;
    sleep 5;
    ;; 
  kali) # Matches "kali"
    echo "This machine is running Kali Linux";
    sleep 5;	
    ;;
  zorin) # Matches "zorin"
    echo "This machine is running Zorin";
    sleep 5;
    ;;	 
  *) # This is the default case
    echo "This machine is running $ID";
    sleep 5; 
    ;;
esac # ends case statement

#Adds non-free and non-free-firmware components

BroadcomWifi=$(lspci | grep Netw | grep -o 'BCM[0-9]\+') #searches for Broadcom wifi driver for older Macs
case $BroadcomWifi in
    BCM4331) # Matches BCM4331
        echo "This machine needs firmware for the Broacdom BCM4331";
	sudo tee /etc/apt/sources.list.d/testlist.list <<EOL
 	#Adds non-free and non-free-firmware components
        deb https://deb.debian.org/debian bookworm contrib non-free
EOL 
	sudo apt install firmware-b43-installer;
 	unset BroadcomWifi;
 	;;
esac


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
sudo nala install mirage -y
sudo nala install snapd -y
sudo snap install discord
sudo snap install bitwarden
sudo snap install todoist
sudo snap install steam
sudo snap install okular
sudo snap install rpi-imager
sudo snap install cura-slicer
sudo snap install sublime-text --classic
sudo snap install apple-music-for-linux
sudo snap install audible-for-linux

#echo “Preparing cryptographic signatures for advance setup. Proceed?”

#interactiveyn

sudo apt autoclean

echo "Installation complete. Media will now self delete. Have a good day."

sudo shutdown -r +1
sleep 8
rm -- $0
