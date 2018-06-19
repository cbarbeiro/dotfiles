########################################################
#|NAME: CHANGE DIRECTORY                               #
#|# Leverage pushd command when using cd               #
########################################################
function cd() {
  if [ "$#" = "0" ]
  then
  pushd ${HOME} > /dev/null
  elif [ -f "${1}" ]
  then
    ${EDITOR} ${1}
  else
  pushd "$1" > /dev/null
  fi
}

########################################################
#|NAME: BACK DIRECTORY                                 #
#|# Leverage popd command when using cd                #
########################################################
function bd(){
  if [ "$#" = "0" ]
  then
    popd >/dev/null
  else
    for i in $(seq ${1})
    do
      popd >/dev/null
    done
  fi
}

########################################################
#|NAME: PATH                                           #
#|# Prints paths in $PATH                              #
########################################################
function path(){
    old=$IFS
    IFS=:
    printf "%s\n" $PATH
    IFS=$old
}

########################################################
#|NAME: EXECUTIFY                                      #
#|# Run or make runnable $FILE                         #
########################################################
function executify(){
	file=${1}
	if  [ -f ${file} -a ! -x ${file} ]
	then
		chmod +x ${file}
	fi
	./${file}
}

########################################################
#|NAME: SHOW NOTIFICATION                              #
#|# Shows a notification in desktop	with $1	       #
########################################################
function show_notification(){
	if [ "x${1}" == "x" ]
	then
	    message='Hello World'
	else
	    message=${1} ${2} ${3} ${4} ${5}
	fi
	echo $message
	notify-send -u normal -t 10 -i info $(whoami) "$message"
}

########################################################
#|NAME: ONE LINERS                                     #
#|# Quick and useful one-line functions                #
########################################################
function fname() { find . -name "*$@*"; }
function finame() { find . -iname "*$@*"; }
function fregex() { find . -regextype posix-egrep -regex "*$@*"; }
function firegex() { find . -regextype posix-egrep -iregex "*$@*"; }
function mkdircd () { mkdir -p "$@" && eval cd "\"\$$#\""; }

########################################################
#|NAME: WHICH                                          #
#|# Show information on runnable                       #
########################################################
function which(){
	file=${1}
	type -t $file
	/usr/bin/which $file
	whatis $file
}

########################################################
#|NAME: SOURCE DOTFILES                                #
#|# Source our dotfiles so changes are available       #
########################################################
function source-dotfiles(){
	source ~/.bash_aliases
	source ~/.bash_functions
	source ~/.bash_exports
}

########################################################
#|NAME: BOOKMARKS MANAGER			       #
#|# Functions related to CRUD folder bookmarks	       #
########################################################

# Show bookmarks list and allow to cd into selected folder
function bm() {
	local dest_dir=$(bm-ls | fzf --tac --cycle)
	if [[ $dest_dir != '' ]]; then
		eval cd $dest_dir
	fi
}

# ADD current dir to bookmarks list
function bm-add () {
	local curr_dir="${PWD}"
	local curr_entry=$curr_dir
	#if there's comments - add them
	if [[ $# -ne 0 ]]; then
		curr_entry=$curr_dir" # $*"
	fi

	if ! grep -Fxq "$curr_dir" $BM_DIRECTORY; then
		echo "$curr_entry" >> $BM_DIRECTORY
		echo "$curr_dir added to bookmarks"
	else
		echo "$curr_dir already in bookmarks"
	fi
}

# EDIT bookmarks list
function bm-edit () { vim $BM_DIRECTORY; }

# CAT bookmarks list
function bm-cat () { cat $BM_DIRECTORY | sed '/^\s*$/d'; }

# LIST bookmarks (and treats output to fzf)
function bm-ls () {
	if [ ! -r $BM_DIRECTORY ]; then
		echo "There's no $BM_DIRECTORY"
		exit 1
	fi

	#cat bookmarks | remove whole line comments | remove empty lines
	bm-cat $BM_DIRECTORY | sed 's/^#.*//g' | sed '/^\s*$/d'
}

########################################################
#|NAME: ARCHIVING				       #
########################################################
# Creates a tar.gz archive from given directory 
function maketar() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }

# Create a ZIP archive of a file or folder.
function makezip() { zip -r "${1%%/}.zip" "$1" ; }

# Extracts most common archives
function extract {
 output=/dev/null
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
 else
    if [ -f $1 ] ; then
        NAME=${1%.*}
        mkdir $NAME > $output && cd $NAME
	cp ../$1 . > $output
        case $1 in
          *.tar.bz2)   tar xvjf ./$1    ;;
          *.tar.gz)    tar xvzf ./$1    ;;
          *.tar.xz)    tar xvJf ./$1    ;;
          *.lzma)      unlzma ./$1      ;;
          *.bz2)       bunzip2 ./$1     ;;
          *.rar)       unrar x -ad ./$1 ;;
          *.gz)        gunzip ./$1      ;;
          *.tar)       tar xvf ./$1     ;;
          *.tbz2)      tar xvjf ./$1    ;;
          *.tgz)       tar xvzf ./$1    ;;
          *.zip)       unzip ./$1       ;;
          *.Z)         uncompress ./$1  ;;
          *.7z)        7z x ./$1        ;;
          *.xz)        unxz ./$1        ;;
          *.exe)       cabextract ./$1  ;;
          *)           echo "extract: '$1' - unknown archive method" ;;
        esac
	
	rm ./$1 > $output

	echo "Entering: "$(pwd)
    else
        echo "$1 - file does not exist"
    fi
fi
}

