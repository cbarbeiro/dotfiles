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
    message=${1}
fi
notify-send -u normal -t 10 -i info '{whoami}' ${1}
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
type -t file
whatis file
which file
}
