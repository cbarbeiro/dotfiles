#!/bin/bash

#SCRIPT
SCRIPT_NAME=$(basename $0 .sh)
SCRIPT_DIR=$(dirname $0)
MAIN_OPTS="aV:v:rdwesh"
ADD_OPTS="t:f:ixl"

#FILE OPTIONS
REPORT_FILE=.report.txt
REPORT_DIR=~
OUTPUT=$REPORT_DIR/$REPORT_FILE
START=$REPORT_DIR/.start

#CONSTANTS
DEBUG=false
EPOCH="19700101"
NOW="now"
INTERACTIVE_TAGS="INTERACTIVE_TAGS"
HEADER_REGEX="^\w*\s[\/\(\)[:digit:]]+$"
ENTRY_REGEX="^[[:digit:]\:\t]+[\w[:blank:]]+"
EDITOR=${EDITOR:-vim}

#CUSTOMIZABLE COMMANDS
TURNOFFSCREEN_CMD="xset dpms force off"
LOGOUT_CMD="cinnamon-screensaver-command -l"

#CUSTOMIZABLE OPTIONS
TURNOFFSCREEN=false
LOGOUT=false
HOLIDAY_ENTRY_START="08:00"
HOLIDAY_ENTRY_STOP="16:00"

#EXTERNAL BUSINESS TAGS
COST_CENTERS="$SCRIPT_DIR/.cost_centers"
CUSTOMERS="$SCRIPT_DIR/.customers"
PROJECTS="$SCRIPT_DIR/.projects"
TAGS="$SCRIPT_DIR/.tags"

#From this script will come these vars used to complete the report
# $COST_CENTER && $COST_CENTER_H
# $CUSTOMER_NAME && $CUSTOMER_NAME_H
# $PROJECT_NAME && $PROJECT_NAME_H
# $TASK && $TASK_H
BIZ_TAGS="$(dirname $0)/.biz_tags"
source $BIZ_TAGS

##############
# FUNCTIONS
##############

function show_usage(){
    printf "Application to report time entries of working tasks.\nThe business tags and task name gets written when the task is finished.

Usage: $(basename $0) [-a [-f time] [-t \"tag name\"] [-i] [-l] [-x]] [-s] [-e] [-w] [-v day] [-V monday] [-r] [-d] [-h]

Options:
-a	add a time entry now
-f	force an entry. Format = %%H:%%M
-t	add a task name instead of the default one
-i	interactively choose every business tag
-l	also logoff computer	(only works with -a. Useful in scripting.)
-x	also turn off the screen	(only works with -l. Useful in scripting.)
-v	add a vacation entry for the given day. Format = %%Y-%%m-%%d
-V	add a vacation entry for a week. any given Monday. Format = %%Y-%%m-%%d
-s	show report
-e	edit report file manually
-w	calculate total working time in the report
-r	remove temp and report files
-d	debug mode\\n"
}

function assert_not_empty(){
	if [[ -z "$1" ]]; then
		echo "$2"
		exit
	fi
}

function assert_valid_hour(){
    assert_not_empty "$1" "No valid hour was given."

    #Parse hour using date
    hour_parsed=$(date +"%H:%M" -d "$1")

    if [[ "$hour_parsed" != "$1" ]]; then
        echo "$1 is NOT a valid HH:MM hour"
        exit
    fi
}

function assert_valid_date(){
    assert_not_empty $1 "No valid date was given."

    #Given day. Change '/' for '-'
    day=$(echo "$1" | tr '/' '-')
    #Parse day using date
    day_parsed=$(date '+%F' -d $1)

    if [[ "$day_parsed" != "$day" ]]; then
        echo "$1 is NOT a valid YYYY-MM-DD date"
        exit
    fi
}

function assert_valid_monday(){
    #Get weekday
    weekday=$(date '+%u' -d "$1")

    if [[ $weekday != "1" ]]; then
		echo -e "$1 is NOT a Monday => $(date -d "$1")\nIn order to add a full holiweek insert the corresponding Monday.\n"
		exit
	fi
}

#Input: "01:10"
#Output: 4200
function get_seconds(){
	#replace ':' for a space and remove leading zeros
	read -r h m <<< $(echo "$1" | tr ':' ' ' | sed -E 's/\b0?//g')
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

		if [[ "$line" =~ $HEADER_REGEX ]]; then
			$DEBUG && echo "IS_HEADER"

			if [[ $day_diff -gt 0 ]]; then
				#print total time of last day parsed
				echo -e "\nDay Total: $((day_diff/60/60))h $((day_diff/60%60))m\n"

				#reset timer
				day_diff=0
			fi

			echo -e "\n\t\t$line"

		elif [[ "$line" =~ $ENTRY_REGEX ]]; then
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
	[[ $day_diff -gt 0 ]] && echo -e "\nDay Total: $((day_diff/60/60))h $((day_diff/60%60))m"

	#print whole report time
	[[ $total_diff -gt 0 ]] && echo -e "\nReport Total Time: $((total_diff/60/60))H $((total_diff/60%60))m\n"
}

function register_holiweek() {
    assert_valid_date $1
    assert_valid_monday $1

	for i in {0..4}
	do
		next_day=$(date +%F -d "$1 + $i day")
		register_holiday $next_day
	done
}

function register_holiday() {
   assert_valid_date $1

	echo -e "\n$(date $"+%A (%d/%m/%Y)" -d $1)" >> $OUTPUT
	printf "$HOLIDAY_ENTRY_START\\t$HOLIDAY_ENTRY_STOP\\t$COST_CENTER_H\\t$CUSTOMER_NAME_H\\t$PROJECT_NAME_H\\t$TASK_H\\n" >> $OUTPUT
	echo -e "\nHoliday Task \"$TASK_H\" added for day $date\n\n$(tail -2 $OUTPUT)"
}

function register_time_entry() {
    #Set default time entry as 'now'
    time_entry=$(date +"%H:%M")

    if [[ $1 != $NOW ]]; then
		time_entry=$(date +"%H:%M" -d "$1")
	fi

    assert_valid_hour "$time_entry"

	if [[ -e $START ]]; then

        #Check for TASK only if we're writing it...
        if [[ $2 = $INTERACTIVE_TAGS ]]; then
            COST_CENTER=$(cat $COST_CENTERS | fzf --tac --cycle)
            CUSTOMER_NAME=$(cat $CUSTOMERS | fzf --tac --cycle)
            PROJECT_NAME=$(cat $PROJECTS | fzf --tac --cycle)
            TASK=$(cat $TAGS | fzf --tac --cycle --print-query | tr -d '\n')

        elif [[ ! -z "$2" ]]; then
            TASK="$2"
        fi

		rm $START

        # if subtraction is negative, means a day has passed.
        entry_start=$(get_seconds "$(tail -1 $OUTPUT | tr -d '\t')")
		entry_stop=$(get_seconds "$time_entry")
		entry_diff=$((entry_stop - entry_start))

        if [[ $entry_diff -lt 0 ]]; then

            #end task for the day
            printf "23:59\t" >> $OUTPUT
		    printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\n" >> $OUTPUT

		    #add header for new day
		    echo -e "\n$(date $"+%A (%d/%m/%Y)")" >> $OUTPUT

		    #start new task
		    printf "00:01\t" >> $OUTPUT
        fi

        #end task and append biz tags
		printf "$time_entry\t" >> $OUTPUT
		printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\t\n" >> $OUTPUT
		echo -e "Task $TASK finished\n\n$(tail -1 $OUTPUT)"
	else
		#Grep the current day in the report file
		[[ -e $OUTPUT ]] && grep -Fq $(date +"%d/%m/%Y") $OUTPUT
		is_new_day=$?
		if [ "$is_new_day" -ne 0 ]; then
			echo -e "\n$(date $"+%A (%d/%m/%Y)")" >> $OUTPUT
		fi
		printf "$time_entry\t" >> $OUTPUT
		touch $START
		echo "New task started at $(tail -1 $OUTPUT)"
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

#If no arguments are given, show_usage
if [[ -z $1 ]]; then
    show_usage
    exit
fi

#OPTIONS
while getopts "$MAIN_OPTS" opt; do
    case $opt in
        a)
            #Keeps the time (start|end) of the task
            TIME=$NOW
            #Keeps the task setting option
            TAG=""

            while getopts "$ADD_OPTS" optA; do
                case $optA in
                    t)
                        #Custom task name. TAG="custom value"
                        TAG="$OPTARG"
                        ;;
                    f)
                        #Custom time.
                        TIME="$OPTARG"
                        ;;
                    i)
                        if ! command -v fzf > /dev/null; then
                            echo "This option depends on 'fzf'. Please install it first in order to use this."
                            exit
                        fi

                        #Tags are chosen interactively
                        TAG="$INTERACTIVE_TAGS"
                        ;;
                    x)
                        #Turn off screen after appending entry.
                        TURNOFFSCREEN=true
                        ;;
                    l)
                        #Logout after appending entry.
                        LOGOUT=true
                        ;;
                esac
            done

            register_time_entry "$TIME" "$TAG"

            if [[ $TURNOFFSCREEN == true ]]; then
                echo $TURNOFFSCREEN_CMD;
            fi

            if [[ $LOGOUT == true ]]; then
                echo $LOGOUT_CMD;
            fi

            ;;
        v)
            register_holiday $OPTARG
            ;;
        V)
            register_holiweek $OPTARG
            ;;
        r)
            echo "This will clear a temp file and the report file."
            rm -i -v $OUTPUT $START
            ;;
        d)
            DEBUG=true
            set -x
            ;;
        w)
            calculate_total_time
            ;;
        e)
            $EDITOR $OUTPUT
            ;;
        s)
            cat $OUTPUT
            echo -e "\n"
            $DEBUG && echo "Report file path: $OUTPUT"
            ;;
        h)
            show_usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done