#!/bin/bash

#DEBUG MODE
DEBUG=false

#FILE OPTIONS
TEMP_DIR=/tmp/timer
OUTPUT=$TEMP_DIR/report.txt
START=$TEMP_DIR/.start
BIZ_TAGS="$(dirname $0)/.biz_tags"

#From this script will come these vars used to complete the report
# $COST_CENTER && $COST_CENTER_H
# $CUSTOMER_NAME && $CUSTOMER_NAME_H
# $PROJECT_NAME && $PROJECT_NAME_H
# $TASK && $TASK_H
source $BIZ_TAGS

#MISC OPTIONS
TURNOFFSCREEN=false
HOLIDAY_ENTRY_START="08:00"
HOLIDAY_ENTRY_STOP="16:00"

#COMPATIBILITY
if [[ "$OSTYPE" == "darwin"* ]; then
       $IS_MAC=true
fi

##############
# FUNCTIONS
##############
function register_week() {
	if [[ -z $1 ]]; then
		echo "No date was given."
		exit
	fi

	monday=$(date '+%F' -d $1)
	if [[ "$monday" != "$1" ]]; then
		echo $1 is NOT a valid YYYY-MM-DD date
		exit
	elif [[ $(date '+%u' -d $monday) != "1" ]]; then
		echo -e "$1 is NOT a Monday => $(date -d $monday)\nIn order to add a full holiweek insert the corresponding Monday.\n"
		exit
	fi

	for i in {0..4}
	do
		next_day=$(date +%F -d "$monday + $i day")
		register_day $next_day
	done
}

function register_day() {
#
# check how to parse date for mac systems
#
# day="$(date -j -f "%Y-%m-%d" "2018-10-01" "+%F")"
#
	if [[ -z $1 ]]; then
		echo "No date was given."
		exit
	fi

	day=$(date '+%F' -d $1)
	if [[ "$day" != "$1" ]]; then
		echo $1 is NOT a valid YYYY-MM-DD date
		exit
	fi

	echo -e "\n$(date $"+%A (%d/%m/%Y)" -d $day)" >> $OUTPUT
	printf "$HOLIDAY_ENTRY_START\\t$HOLIDAY_ENTRY_STOP\\t$COST_CENTER_H\\t$CUSTOMER_NAME_H\\t$PROJECT_NAME_H\\t$TASK_H\\t\\n" >> $OUTPUT
	$DEBUG && echo -e "\nHoliday Task \"$TASK_H\" added for day $day\n\n$(tail -2 $OUTPUT)"
}

function register_time() {

	if [[ -z $1 ]]; then
		time_entry=$(date +"%H:%M")
	else
		time_entry=$(echo $1)
	fi

	if [[ -e $START ]]; then
		rm $START

		printf $(echo $time_entry)\\t >> $OUTPUT
		printf "$COST_CENTER\\t$CUSTOMER_NAME\\t$PROJECT_NAME\\t$TASK\\t\\n" >> $OUTPUT
		$DEBUG && echo -e "Task $TASK finished\n\n$(tail -1 $OUTPUT)"
	else
		#Grep the current day in the report file
		[[ -e $OUTPUT ]] && grep -Fq $(date +"%d/%m/%Y") $OUTPUT
		is_new_day=$?
		if [ "$is_new_day" -ne 0 ]; then
			echo -e $(date $"+%A (%d/%m/%Y)") >> $OUTPUT
		fi
		printf $(echo $time_entry)\\t >> $OUTPUT
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
	echo -e "\n"
	$DEBUG && echo "Report file path: $OUTPUT"
	exit

#add time entry
elif [[ $1 = "-a" ]]; then
	
	if [[ $2 = "-f" ]]; then
		register_time $3
	else
		register_time
	fi

	#also turn screen off
	if [[ $3 = "-x" ]] || [[ $4 = "-x" ]]; then
		TURNOFFSCREEN=true
	fi

	#also log out
	if [[ $2 = "-l" ]] || [[ $3 = "-l" ]]; then
		$TURNOFFSCREEN && xset dpms force off;
		cinnamon-screensaver-command -l;
	fi

#report a single holiday
elif [[ $1 = "-hd" ]]; then
	register_day $2

#report a whole week of holidays
elif [[ $1 = "-hw" ]]; then
	register_week $2

#edit report manually
elif [[ $1 = "-e" ]]; then
	vim $OUTPUT

#clear temp files
elif [[ $1 = "-c" ]]; then
	rm $START
	echo "deleted temp files"

#clear temp dir
elif [[ $1 = "-call" ]]; then
	read -p "This will clear everything including the report file. Are you sure? [y/N] " -n 1 -r
	echo #newline
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		rm -r $TEMP_DIR/
		echo "deleted timer directory (temp + report files)"
	else
		echo "clear skipped"
	fi

#show help
elif [[ $1 = "-h" ]] || [[ -z $1 ]]; then
	printf "Application to report time entries of login and logout times.

Usage: $0 [-s] [-c] [-call] [-e] [-a [-f entry] [-l [-x]]] [-hd day | -hw day] [-d]

Options:
-s	show report
-c	clear temp files
-call	clear temp and report file
-e	edit report file manually
-a	add a time entry. Format = %%H:%%M
-f	force an entry
-l	logoff computer	
-x	turn off the screen (only works with -l)
-hd	add a \033[1mh\033[0moli\033[1md\033[0may entry for given day. Format = %%Y-%%m-%%d
-hw	add a \033[1mh\033[0moli\033[1mw\033[0meek entry for given \033[1mMonday\033[0m. Format = %%Y-%%m-%%d
-d	debug mode\\n"
	exit
fi
