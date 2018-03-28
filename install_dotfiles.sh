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
for dotfile in bashrc bash_aliases bash_exports bash_functions dir_bookmarks #vimrc gitconfig htop
do
	if [[ -L ~/.${dotfile} ]]; then
		rm ~/.${dotfile}
	fi
	ln -sv $(pwd)/${dotfile} ~/.${dotfile}
done

echo "Done!"
