#!/bin/bash

########################################################
#	CONSTANTS										   #
########################################################
# Change this to wherever you keep custom scripts, this should be in you $PATH variable
SCRIPTS_FOLDER=~/.scripts

########################################################
#	SETUP											   #
########################################################
# Determine platform first
export platform='unknown'
uname=$(uname)
if [[ "x${uname}" == "xDarwin" ]]; then
    export platform='mac'
elif [[ "x${uname}" == "xLinux" ]]; then
    export platform='linux'
fi


# install main config files
for dotfile in bashrc bash_aliases bash_exports bash_functions #vimrc gitconfig htop
do
	if [[ -L ~/.${dotfile} ]]; then
		rm ~/.${dotfile}
	fi
	ln -sv $(pwd)/${dotfile} ~/.${dotfile}
done

# install scripts folder
if [ ! -d ${SCRIPTS_FOLDER} ]
then
    mkdir -pv ${SCRIPTS_FOLDER}
fi

echo "Done!"
