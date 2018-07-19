#!/bin/bash

#DEBUG MODE
DEBUG=false

#FILE OPTIONS
TEMP_DIR=/tmp/timer
OUTPUT=$TEMP_DIR/report.txt
START=$TEMP_DIR/.start

#DEFAULT REPORTING
BIZ_UNIT="RCS+"
PRODUCT="RCS+"
PM="Rui Gil"
TASK="Development"

#MISC OPTIONS
TURNOFFSCREEN=false

##############
# FUNCTIONS
##############

function register_time () {
	if [[ -e $START ]]; then
		rm $START
		
		printf $(date +%H:%M)\\t >> $OUTPUT 
		printf "$BIZ_UNIT\\t$PRODUCT\\t$PM\\t$TASK\\t\n" >> $OUTPUT 
		$DEBUG && echo -e "Task $TASK finished\n$(tail -1 $OUTPUT)"
	else
		printf $(date +%H:%M)\\t >> $OUTPUT 
		touch $START
		$DEBUG && echo "Task \"$TASK\" started at $(tail -1 $OUTPUT)"
	fi
}

############
# MAIN
############

#Create temp dir if doesn't exist
if [[ ! -d $TEMP_DIR ]]; then
	mkdir $TEMP_DIR
fi

#if last argument is -d activate debug
if [[ ${@: -1} = "-d" ]]; then
	DEBUG=true
fi

#Check first argument
#show report
if [[ $1 = "-s" ]]; then
	cat $OUTPUT
	exit

#add time entry
elif [[ $1 = "-a" ]]; then
	
	register_time

	#also turn screen off
	if [[ $3 = "-x" ]]; then
		TURNOFFSCREEN=true
	fi

	#also log out
	if [[ $2 = "-l" ]]; then
		$TURNOFFSCREEN && xset dpms force off;
		cinnamon-screensaver-command -l; 
	fi

#clear temp files
elif [[ $1 = "-c" ]]; then
	rm $START
	echo "deleted start and stop files"

#clear temp dir
elif [[ $1 = "-call" ]]; then
	rm -r $TEMP_DIR/
	echo "deleted temp directory"

#show help
elif [[ $1 = "-h" ]] || [[ -z $1 ]]; then
	printf "Application to report time entries of login and logout times.

Usage: $0 [-s] [-c] [-call] [-a [-l [-x]] [-d] ] 

Options:
-s	show report
-c	clear temp files
-call	clear temp and report file
-a	add entry
-l	logoff computer	
-x	turn off the screen (only works with -l)
-d	debug mode (only works with -a)\n"
	exit
fi
