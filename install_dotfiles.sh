#!/bin/bash

profile=$1

########################################################
#	CONSTANTS										   #
########################################################

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

########################################################
#	INSTALL											   #
########################################################

# install main config files
echo -e "Copying base configs...\n"
for dotfile in bashrc bash_aliases bash_exports bash_functions dir_bookmarks #vimrc gitconfig htop
do
	if [[ -L ~/.${dotfile} ]]; then
		rm ~/.${dotfile}
	fi
	ln -sv $(pwd)/${dotfile} ~/.${dotfile}
done

if [[ $profile = "work" ]]; then

	echo -e "\nCopying work configs...\n"

	for dotfile in bash_aliases_work bash_exports_work bash_functions_work dir_bookmarks_work
	do
		if [[ -L ~/.${dotfile} ]]; then
			rm ~/.${dotfile}
		fi
		ln -sv $(pwd)/${dotfile} ~/.${dotfile}
	done
fi

echo    # move to a new line
read -p "Install hard-copy to user root? [y/n] (root files only contain base files)" -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo -e "Copying base configs to root...\n"
	for dotfile in bashrc bash_aliases bash_exports bash_functions dir_bookmarks #vimrc gitconfig htop
	do
		if [[ -L /root/.${dotfile} ]]; then
			sudo rm /root/.${dotfile}
		fi
		sudo cp -v $(pwd)/${dotfile} /root/.${dotfile}
	done
	echo "Adjusting PS1 prompt of root"
			#grep the line | gets the line number | removes possible ANSI coloring`
	ps1_line_number=$(grep -n "38;5;10m" bashrc | cut -f1 -d: | sed 's/\x1b\[[0-9;]*m//g')
	sudo sed -i ${ps1_line_number}s/"38;5;10m"/"0\;31m"/g /root/.bashrc
fi

echo "Done!"
