#!/bin/bash

read -p "continue test? (y/n)" yn

case $yn in
	[yY] ) echo Ok, proceeding;;
	[nN] ) echo Exiting;
		exit;;
	* ) echo Invalid response;
		exit 1;;
esac