#!/bin/bash

#DEBUG MODE
DEBUG=false

#SCRIPT
SCRIPT_NAME=$(basename $0 .sh)
SCRIPT_DIR=$(dirname $0)

#FILE OPTIONS
REPORT_FILE=.report.txt
REPORT_DIR=~
OUTPUT=$REPORT_DIR/$REPORT_FILE
START=$REPORT_DIR/.start

#CUSTOMIZABLE OPTIONS
BIZ_TAGS="$(dirname $0)/.biz_tags"
TURNOFFSCREEN=false
HOLIDAY_ENTRY_START="08:00"
HOLIDAY_ENTRY_STOP="16:00"

#From this script will come these vars used to complete the report
# $COST_CENTER && $COST_CENTER_H
# $CUSTOMER_NAME && $CUSTOMER_NAME_H
# $PROJECT_NAME && $PROJECT_NAME_H
# $TASK && $TASK_H
source $BIZ_TAGS

#CONSTANTS
EPOCH="19700101"
NOW="now"

##############
# FUNCTIONS
##############

function assertNotEmpty(){
	if [[ -z $1 ]]; then
		echo $2
		exit
	fi
}

#Input: "01:10"
#Output: 4200
function get_seconds(){
	#replace ':' for a space and remove leading zeros
	read -r h m <<< $(echo "$1" | tr ':' ' ' | sed -r 's/\b0?//g')
	$DEBUG && echo "hours=$h minutes=$m"
	echo $(( (h*60*60)+(m*60) ))
}

function calculate_total_time() {
	total_diff=0
	day_diff=0

	while IFS='' read -r line || [[ -n "$line" ]]; do
		
		$DEBUG && echo -e "Line read from file: $line"

		if [[ -z $line ]]; then
			$DEBUG && echo "continuing..."
			continue
		fi


		day_parsed=$(echo -e $line | sed 's/[^0-9\/]*//g' | tr '/' '\n' | tac | tr -d '\n')
		$DEBUG && echo "day_parsed=$day_parsed"

		header=$([[ ! -z $day_parsed ]] && date $"+%A (%d/%m/%Y)" -d "$day_parsed" 2> /dev/null)
		$DEBUG && echo "header=$header"

		if [[ $line = $header ]]; then
			$DEBUG && echo "IS_HEADER"

			if [[ $day_diff -gt 0 ]]; then
				#print total time of last day parsed
				echo -e "\nDay Total: $((day_diff/60/60))h $((day_diff/60%60))m\n"

				#reset timer
				day_diff=0
			fi

			echo -e "\n\t\t$header"

		elif [[ $line =~ ^([\d\:\s]*).*$ ]]; then
			$DEBUG && echo "IS_ENTRY"

			#create array with the entry separated by spaces
			columns=( $line )
			$DEBUG && printf "ENTRY START=%s STOP=%s\n ${columns[0]} ${columns[1]}"
			
			entry_start=$(get_seconds "${columns[0]}")
			entry_stop=$(get_seconds "${columns[1]}")
			entry_diff=$((entry_stop - entry_start))

			#show counter for each entry
			echo -e "$((entry_diff / 60 / 60))h $(( (entry_diff / 60) % 60))m\t<\t$line"

			#update day counter
			day_diff=$((day_diff + entry_diff ))

			#update total counter
			total_diff=$((total_diff + entry_diff ))
		fi

	done < "$OUTPUT"

	#print last day parsed
	[[ $day_diff -gt 0 ]] && echo -e "\nDay Total: $((day_diff/60/60))h $((day_diff/60%60))m\n"

	#print whole report time
	[[ $total_diff -gt 0 ]] && echo -e "\nReport Total Time: $((total_diff/60/60))H $((total_diff/60%60))m\n"
}

function register_holiweek() {

    assertNotEmpty $1 "No date was given."

	monday=$(date '+%F' -d $1)
	if [[ "$monday" != "$1" ]]; then
		echo "$1 is NOT a valid YYYY-MM-DD date"
		exit
	elif [[ $(date '+%u' -d $monday) != "1" ]]; then
		echo -e "$1 is NOT a Monday => $(date -d $monday)\nIn order to add a full holiweek insert the corresponding Monday.\n"
		exit
	fi

	for i in {0..4}
	do
		next_day=$(date +%F -d "$monday + $i day")
		register_holiday $next_day
	done
}

function register_holiday() {

    assertNotEmpty $1 "No date was given."

	day=$(date '+%F' -d $1)
	if [[ "$day" != "$1" ]]; then
		echo "$1 is NOT a valid YYYY-MM-DD date"
		exit
	fi

	echo -e "\n$(date $"+%A (%d/%m/%Y)" -d $day)" >> $OUTPUT
	printf "$HOLIDAY_ENTRY_START\\t$HOLIDAY_ENTRY_STOP\\t$COST_CENTER_H\\t$CUSTOMER_NAME_H\\t$PROJECT_NAME_H\\t$TASK_H\\t\\n" >> $OUTPUT
	echo -e "\nHoliday Task \"$TASK_H\" added for day $day\n\n$(tail -2 $OUTPUT)"
}

function register_time_entry() {

    if [[ $1 = $NOW ]]; then
		time_entry=$(date +"%H:%M")
	else
		time_entry=$(date +"%H:%M" -d "$1")

        #if date is invalid, exit
		[[ $time_entry != $1 ]] && exit
	fi

	if [[ $2 = "CHOOSE_TAGS" ]]; then
		COST_CENTER=$(cat $SCRIPT_DIR/.cost_centers | fzf --tac --cycle)
		CUSTOMER_NAME=$(cat $SCRIPT_DIR/.customers | fzf --tac --cycle)
		PROJECT_NAME=$(cat $SCRIPT_DIR/.projects | fzf --tac --cycle)
		TASK=$(cat $SCRIPT_DIR/.tags | fzf --tac --cycle --print-query)
	elif [[ $2 = "TAG="* ]]; then
		TASK=${2/"TAG="/""}
	fi

	if [[ -e $START ]]; then
		rm $START

        # if subtraction is negative, means a day has passed.
        entry_start=$(get_seconds "$(tail -1 $OUTPUT | tr -d '\t')")
		entry_stop=$(get_seconds "$time_entry")
		entry_diff=$((entry_stop - entry_start))

        if [[ $entry_diff -lt 0 ]]; then

            #end task for the day
            printf "23:59\t" >> $OUTPUT
		    printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\t\n" >> $OUTPUT

		    #add header for new day
		    echo -e "\n$(date $"+%A (%d/%m/%Y)")" >> $OUTPUT

		    #start new task
		    printf "00:01\t" >> $OUTPUT
        fi

        #end task and append biz tags
		printf "$time_entry\t" >> $OUTPUT
		printf "$COST_CENTER\\t$CUSTOMER_NAME\\t$PROJECT_NAME\\t$TASK\\t\\n" >> $OUTPUT
		echo -e "Task $TASK finished\n\n$(tail -1 $OUTPUT)"
	else
		#Grep the current day in the report file
		[[ -e $OUTPUT ]] && grep -Fq $(date +"%d/%m/%Y") $OUTPUT
		is_new_day=$?
		if [ "$is_new_day" -ne 0 ]; then
			echo -e "\n$(date $"+%A (%d/%m/%Y)")" >> $OUTPUT
		fi
		printf $(echo $time_entry)\\t >> $OUTPUT
		touch $START
		echo "Task \"$TASK\" started at $(tail -1 $OUTPUT)"
	fi
}

############
# MAIN
############

#ASSERTIONS

##COMPATIBILITY
if [[ "$OSTYPE" == "darwin"* ]]; then
       IS_MAC=true
fi

##FOLDERS

#if last argument is -d activate debug
if [[ ${@: -1} = "-v" ]]; then
	DEBUG=true
fi

#OPTIONS

#Check first argument
#show report
if [[ $1 = "-s" ]]; then
	cat $OUTPUT
	echo -e "\n"
	$DEBUG && echo "Report file path: $OUTPUT"
	exit

#add time entry
elif [[ $1 = "-a" ]]; then
	
	if [[ $2 = "-f" ]] && [[ $4 = "-tn" ]]; then
		register_time_entry "$3" "TAG=$5"
		exit
	elif [[ $2 = "-f" ]] && [[ $4 = "-i" ]]; then
		register_time_entry "$3" "CHOOSE_TAGS"
		exit
	fi

	if [[ $2 = "-f" ]]; then
		register_time_entry "$3"

	elif [[ $2 = "-i" ]]; then
	    # DEPENDENCIES
        if ! command -v fzf > /dev/null; then
            echo "This option depends on 'fzf'. Please install it first in order to use this."
        fi

		register_time_entry $NOW "CHOOSE_TAGS"

	elif [[ $2 = "-tn" ]]; then
		register_time_entry $NOW "TAG=$3"
	else
		register_time_entry $NOW
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
	register_holiday $2

#report a whole week of holidays
elif [[ $1 = "-hw" ]]; then
	register_holiweek $2

#calculate total time of entries
elif [[ $1 = "-t" ]]; then
	calculate_total_time

#edit report manually
elif [[ $1 = "-e" ]]; then
	vim $OUTPUT

#clear temp and report files
elif [[ $1 = "-d" ]]; then
	echo "This will clear a temp file and the report file."
	rm -i -v $OUTPUT $START

#show help
elif [[ $1 = "-h" ]] || [[ -z $1 ]]; then
	printf "Application to report time entries of login and logout times.

Usage: $(basename $0) [-s] [-e] [-a [-f entry] [-i] [-tn \"tag name\"] [-l [-x]]] [-t] [-hd day | -hw day] [-d] [-v]

Options:
-s	show report
-e	edit report file manually
-a	add a time entry. Format = %%H:%%M
-f	force an entry
-tn	add a task name instead of the default one
-i	interactively choose every business tag
-t	total of time entries in report
-hd	add a \033[1mh\033[0moli\033[1md\033[0may entry for given day. Format = %%Y-%%m-%%d
-hw	add a \033[1mh\033[0moli\033[1mw\033[0meek entry for given \033[1mMonday\033[0m. Format = %%Y-%%m-%%d
-l	also logoff computer	(only works with -a)
-x	also turn off the screen	(only works with -l)
-d	delete temp and report files
-v	verbose mode\\n"
	exit
fi
