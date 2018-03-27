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
	if [[ -f ~/.${dotfile} ]]; then
        echo 'Moving '~/.${dotfile}' to '~/.${dotfile}'.old'
        mv ~/.${dotfile} ~/.${dotfile}.old
    fi
    ln -sv $(pwd)/${dotfile} ~/.${dotfile}
done

# install scripts folder
if [ ! -d ${SCRIPTS_FOLDER} ]
then
    mkdir -pv ${SCRIPTS_FOLDER}
fi

# put scripts in scripts folder
for script in $(pwd)/*
do
    if [ ! -e ${SCRIPTS_FOLDER}/$(basename ${script}) ]
    then   
        ln -sv $(readlink -f ${script}) ${SCRIPTS_FOLDER}/$(basename ${script})
    fi
done

echo "Done!"
