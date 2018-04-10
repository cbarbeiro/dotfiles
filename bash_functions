########################################################
#|NAME: CHANGE DIRECTORY							   #
#|# Leverage pushd command when using cd			   #
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
#|NAME: BACK DIRECTORY								   #
#|# Leverage popd command when using cd				   #
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
#|NAME: PATH										   #
#|# Prints paths in $PATH							   #
########################################################
function path(){
    old=$IFS
    IFS=:
    printf "%s\n" $PATH
    IFS=$old
}
alias PATH='path'

########################################################
#|NAME: EXECUTIFY									   #
#|# Run or make runnable $FILE						   #
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
#|NAME: SHOW NOTIFICATION							   #
#|# Shows a notification in desktop	with $1			   #
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
#|NAME: FIND FUNCTIONS								   #
#|# Functions to find files $1						   #
########################################################
function fname() { find . -name "*$@*"; }
function finame() { find . -iname "*$@*"; }
function fregex() { find . -regextype posix-egrep -regex "*$@*"; }
function firegex() { find . -regextype posix-egrep -iregex "*$@*"; }

########################################################
#|NAME: WHICH 										   #
#|# Show information on runnable $1					   #
########################################################
function which(){
file=${1}
type -t $file
/usr/bin/which $file
whatis $file
}

########################################################
#|NAME: BOOKMARKS MANAGER			       #
#|# Functions related to CRUD folder bookmarks	       #
########################################################

# Show bookmarks list and allow to cd into selected folder
function bm() {
local dest_dir=$(bm-ls | fzf )
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
