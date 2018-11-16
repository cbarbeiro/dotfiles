#!/bin/bash

# SCRIPT
SCRIPT_DIR=$(dirname $0)
SCRIPT_NAME=$(basename $0 .sh)
CONFIG="$(dirname $0)/.config"
MAIN_OPTS="aV:v:d:rweshmbp"
ADD_OPTS="t:f:ixl"

# EXTERNAL BUSINESS TAGS
COST_CENTERS="$SCRIPT_DIR/.cost_centers"
CUSTOMERS="$SCRIPT_DIR/.customers"
PROJECTS="$SCRIPT_DIR/.projects"
TAGS="$SCRIPT_DIR/.tags"

# CONSTANTS
DEBUG=false
EPOCH="19700101"
NOW="now"
TIMESTAMP=$(date +%s)
INTERACTIVE_TAGS="INTERACTIVE_TAGS"
HEADER_REGEX="^\w*\s[\/\(\)[:digit:]]+$"
NEW_WEEK_REGEX="^Monday.*$"
ENTRY_REGEX="^[[:digit:]\:\t]+[\w[:blank:]]+"
IS_NUMBER_REGEX="^[0-9]*$"
RQ_SUCCESS="Submission success"
RQ_ERR_AUTH="Authentication error"
EDITOR=${EDITOR:-vim}

# COLORS
C_RESET=$(tput sgr0)
C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_BLUE=$(tput setaf 4)

# RETURN STATUSES
SUCCESS=0
ERR_OTHER=1
ERR_AUTH=2

# From this script will come custom configurations used to complete the report
source $CONFIG

# FILE OPTIONS
REPORT_FILE=$REPORT_DIR/$REPORT_FILENAME
START=$REPORT_DIR/.start

##############
# FUNCTIONS
##############

function show_usage(){
    printf "Application to report time entries of working tasks.\nTask details are written when the task is finished.

Usage: $(basename $0) [-h] [-a [-f time] [-t \"tag name\"] [-i]]
                        [-s] [-e] [-w] [-v day] [-V monday] [-p] [-m] [-b] [-r]

Local options:

-a	add a time entry now (a report entry is made of two time entries)
    -f	with -a, force a time entry. Format = %%H:%%M
    -t	with -a, add a task name instead of the default one
    -i	with -a, interactively choose every business tag
-d      delete last X lines of report (default=1)
-e	edit report file manually
-r	remove temp and report files
-s	show report
-v	add a vacation entry for the given day. Format = %%Y-%%m-%%d
-V	add a vacation entry for a week. any given Monday. Format = %%Y-%%m-%%d
-w	calculate total working time in the report

Server options:

-b	get business tags from server
-m	get missing reports from server
-p	post report to server
\\n"

#-l	with -a, logoff computer after reporting
#-x	with -a, turn off the screen after reporting
}

function validate_empty_report(){
    if [[ ! -e $REPORT_FILE ]];then
        printf "Report file doesn't exist yet. Use -a to add a task...\n"
        exit $SUCCESS
    fi

    grep -q '[^[:space:]]' $REPORT_FILE
    if [[ $? -eq 1 ]]; then
        printf "Report is empty. Use -a to add a task...\n"
        exit $SUCCESS
    fi
}

function checkOrCreateDir() {
    #Create temp dir if doesn't exist
    if [[ ! -d $1 ]]; then
        mkdir $1
    fi
}

function decode_base64(){
    string=$1
    decode_arg="-d"

    if [[ $IS_MAC = true ]]; then
        decode_arg="-D"
    fi

    echo "$(base64 $decode_arg <<< "$1")"
}

# *BSD parse date function
# input: parse_date "input_date" "output_format" "increment"
# output: the result of the following date command
#
# Example of *BSD date
# date -j -v "+increment" "+output_format" "input_date"
function parse_date_bsd(){
    output_format=$1
    input_date=$2
    increment=$3

    date_args=( )

    if [[ "$output_format" ]]; then
            date_args=( +"$output_format" )
    fi

    if [[ "$input_date" ]]; then
            #*BSD date needs snowflake US order mm/dd/yyyy
            input_date=$(echo $input_date | tr -d ':' | tr '/' '-' | sed -E 's,([0-9]{4})-([0-9]{2})-([0-9]{2}),\2\3\1,g')
            date_args=( -j "${date_args[@]}" "$input_date")
    fi

    if [[ "$increment" ]]; then
            increment=$increment"d"
            date_args=( -v +$increment "${date_args[@]}" )
    fi

    date_cmd=( date "${date_args[@]}")

    $DEBUG && echo "date_cmd=${date_cmd[@]}" >&2

    #Because of bash auto-quotation skillz, we need to use array expansion so it doesn't add unnecessary (and breaking) quotes
    "${date_cmd[@]}"
}

# POSIX parse date function
# input: parse_date "input_date" "output_format" "increment"
# output: the result of the following date command
#
# Example of *nix date
# date -d "input_date + increment days" "+output_format"
function parse_date_gnu(){
    output_format=$1
    input_date=$2
    increment=$3

    date_args=( )

    if [[ "$output_format" ]]; then
            date_args=( +"$output_format" )
    fi

    if [[ "$increment" ]]; then
            input_date=$input_date" + "$increment"days"
    fi

    if [[ "$input_date" ]]; then
            date_args=( "${date_args[@]}" -d "$input_date")
    fi

    date_cmd=( date "${date_args[@]}")

    $DEBUG && echo "date_cmd=${date_cmd[@]}" >&2

    #Because of bash auto-quotation skillz, we need to use array expansion so it doesn't add unnecessary (and breaking) quotes
    "${date_cmd[@]}"
}

function assert_not_empty(){
	if [[ -z "$1" ]]; then
		echo "$2"
		exit $ERR_OTHER
	fi
}

function assert_valid_hour(){
    assert_not_empty "$1" "No valid hour was given."

    #Parse hour using date
    hour_parsed=$($parse_date "%H:%M" $1)

    if [[ "$hour_parsed" != "$1" ]]; then
        echo "$1 is NOT a valid HH:MM hour"
        exit $ERR_OTHER
    fi
}

function assert_valid_date(){
    assert_not_empty $1 "No valid date was given."

    #Given day. Change '/' for '-'
    day=$(echo "$1" | tr '/' '-')
    #Parse day using date
    day_parsed=$($parse_date "%F" $1)

    if [[ "$day_parsed" != "$day" ]]; then
        echo "$1 is NOT a valid YYYY-MM-DD date"
        exit $ERR_OTHER
    fi
}

function assert_valid_monday(){
    #Get weekday
    weekday=$($parse_date "%u" "$1")

    if [[ $weekday != "1" ]]; then
		printf "\n$1 corresponds to [ $($parse_date "" $1) ]\n\nIn order to add a full holiweek insert the corresponding Monday.\nHere's the calendar to help you choose.\n\n$(cal -m $1)\n"
		exit $ERR_OTHER
	fi
}

# Input: "01:10"
# Output: 4200
function get_seconds(){
	#replace ':' for a space and remove leading zeros
	read -r h m <<< $(echo "$1" | tr ':' ' ' | sed -E 's,0([0-9])+,\1,g')
	echo $(( (h*60*60)+(m*60) ))
}

function calculate_total_time() {
	total_diff=0
	day_diff=0
	week_diff=0

	while IFS='' read -r line || [[ -n "$line" ]]; do

		$DEBUG && printf "Line read from file: $line\n"

		if [[ -z $line ]]; then
			$DEBUG && echo "empty line"
			continue
		fi

		if [[ "$line" =~ $HEADER_REGEX ]]; then
			$DEBUG && echo "IS_HEADER"

			if [[ $day_diff -gt 0 ]]; then
				#print total time of last day parsed
				printf "\n ${C_YELLOW}Day Total: $((day_diff/60/60))h $((day_diff/60%60))m ${C_RESET}\n"

				#reset timer
				day_diff=0
			fi

			if [[ "$line" =~ $NEW_WEEK_REGEX ]] && [[ $week_diff -gt 0 ]]; then
		        $DEBUG && echo "IS_NEW_WEEK"

				#print total time of last week parsed
				if [[ $((week_diff/60/60)) -lt 40 ]]; then
				    printf "\n ${C_RED}Week Total: $((week_diff/60/60))h $((week_diff/60%60))m ${C_RESET}\n"
				else
				    printf "\n ${C_GREEN}Week Total: $((week_diff/60/60))h $((week_diff/60%60))m ${C_RESET}\n"
                fi

				#reset timer
				week_diff=0
			fi

			printf "\n\t   $line\n"

		elif [[ "$line" =~ $ENTRY_REGEX ]]; then
			$DEBUG && echo "IS_ENTRY"

			#create array with the entry separated by spaces
			columns=( $line )
			$DEBUG && printf "ENTRY START=%s STOP=%s\n ${columns[0]} ${columns[1]}"

			entry_start=$(get_seconds "${columns[0]}")
			entry_stop=$(get_seconds "${columns[1]}")
			entry_diff=$((entry_stop - entry_start))

			#show counter for each entry
			printf " $((entry_diff / 60 / 60))h $(( (entry_diff / 60) % 60))m\t| $line\n"

			#update day counter
			day_diff=$((day_diff + entry_diff ))

            #update week counter
			week_diff=$((week_diff + entry_diff ))

			#update total counter
			total_diff=$((total_diff + entry_diff ))
		fi

	done < "$1"

	#print last day parsed
	[[ $day_diff -gt 0 ]] && printf "\n ${C_YELLOW}Day Total: $((day_diff/60/60))h $((day_diff/60%60))m ${C_RESET}\n"

	#print last week parsed
	if [[ $((week_diff/60/60)) -lt 40 ]]; then
        printf "\n ${C_RED}Week Total: $((week_diff/60/60))h $((week_diff/60%60))m ${C_RESET}\n"
    else
        printf "\n ${C_GREEN}Week Total: $((week_diff/60/60))h $((week_diff/60%60))m ${C_RESET}\n"
    fi

	#print whole report time
	[[ $total_diff -gt 0 ]] && printf "\n${C_BLUE}Report Total Time: $((total_diff/60/60))H $((total_diff/60%60))m${C_RESET}\n\n"
}

function register_holiweek() {
    assert_valid_date $1
    assert_valid_monday $1

	for i in {0..4}
	do
		next_day=$($parse_date "%F" "$1" "$i")
		register_holiday $next_day
	done
}

function register_holiday() {
   assert_valid_date $1

	printf "\n$($parse_date "%A (%d/%m/%Y)" $1)\n" >> $REPORT_FILE
	printf "$HOLIDAY_ENTRY_START\\t$HOLIDAY_ENTRY_STOP\\t$COST_CENTER_H\\t$CUSTOMER_NAME_H\\t$PROJECT_NAME_H\\t$TASK_H\\n" >> $REPORT_FILE
	printf "\nHoliday Task \"$TASK_H\" added for day $1\n\n$(tail -2 $REPORT_FILE)\n"
}

function remove_entries(){
    max_lines=$(wc -l $REPORT_FILE | awk "{print \$1}")

    if [[ ! "$1" =~ $IS_NUMBER_REGEX ]]; then
        echo "$1 is not a number...";
        exit $ERR_OTHER
    elif [[ "$1" -lt 1 ]] || [[ "$1" -gt $max_lines ]]; then
        echo "Trying to remove an impossible number of lines. (Min= 1, Max= $max_lines)"
        exit $ERR_OTHER
    fi

    echo "$(cat "$REPORT_FILE" | sed $(($max_lines-$1))q)" > $REPORT_FILE
    echo "$1 line(s) removed"
}

function register_time_entry() {
    #Set default time entry as 'now'
    time_entry=$($parse_date "%H:%M")

    if [[ $1 != $NOW ]]; then
		time_entry=$($parse_date "%H:%M" $1)
	fi

    assert_valid_hour $time_entry

    is_start_task=$(tail -n 1 $REPORT_FILE 2> /dev/null | grep -Eq $"^[[:digit:]]{2}\:[[:digit:]]{2}[[:space:]]$"; echo $?)
    $DEBUG && printf "is_start_task=[$is_start_task]\n"

	if [[ $is_start_task -eq 0 ]]; then

        #Check for TASK only if we're writing it...
        if [[ $2 = $INTERACTIVE_TAGS ]]; then
            COST_CENTER=$(cat $COST_CENTERS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle)
            CUSTOMER_NAME=$(cat $CUSTOMERS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle)
            PROJECT_NAME=$(cat $PROJECTS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle)
            TASK=$(cat $TAGS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle --print-query | tail -n1)

        elif [[ ! -z "$2" ]]; then
            TASK="$2"
        fi

        # if subtraction is negative, means a day has passed.
        entry_start=$(get_seconds "$(tail -1 $REPORT_FILE | tr -d '\t')")
		entry_stop=$(get_seconds "$time_entry")
		entry_diff=$((entry_stop - entry_start))

        if [[ $entry_diff -lt 0 ]]; then

            #end task for the day
            printf "23:59\t" >> $REPORT_FILE
		    printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\n" >> $REPORT_FILE

		    #add header for new day
		    printf "\n$($parse_date $"%A (%d/%m/%Y)")\n" >> $REPORT_FILE

		    #start new task
		    printf "00:01\t" >> $REPORT_FILE

		    #show four lines instead of one
		    lines="-4"
        fi

        #end task and append biz tags
		printf "$time_entry\t" >> $REPORT_FILE
		printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\n" >> $REPORT_FILE
		printf "Task $TASK finished\n\n$(tail ${lines:-"-1"} $REPORT_FILE)\n"
	else
		#Grep the current day in the report file
		[[ -e $REPORT_FILE ]] && grep -Fq $($parse_date "%d/%m/%Y") $REPORT_FILE
		is_new_day=$?

		#Add a new day separator if needed
		if [ "$is_new_day" -ne 0 ]; then
			printf "$($parse_date $"%A (%d/%m/%Y)")\n" >> $REPORT_FILE
		fi

		#Print the time entry
		printf "$time_entry\t" >> $REPORT_FILE
		echo "New task started at $(tail -1 $REPORT_FILE)"
	fi
}

#############
# NETWORKING
############

function httpPostFile() {
	URL="$1"
	FILE="$2"
	CONTENT_TYPE="$3"

	RESULT=$(curl -k -s -X POST -H "Content-Type: $CONTENT_TYPE" --data-binary "@$FILE" -u "$LOGIN:$PASS" $URL)
	echo $RESULT
}

function showMissingReports {
    request="/tmp/soap_req_due_reports_$TIMESTAMP.xml"

	echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ws=\"$WS_REPORTS/\">
	   <soapenv:Header/>
	   <soapenv:Body>
	    	<ws:GetDueReports>
        		<username>$LOGIN</username>
        		<password>$PASS</password>
     		</ws:GetDueReports>
	   </soapenv:Body>
	</soapenv:Envelope>" > "$request"

	RESULT=$(httpPostFile $TT_WS_SR $request text/xml)

    if [[ $IS_MAC = true ]]; then
        RESULT=$(echo $RESULT | sed -e $'s,<,\\\n<,g' | sed -e $'s,>,: ,g' | egrep "<count|<due_reports"| tr -d '<' | tail -r)
    else
        RESULT=$(echo $RESULT | sed -e "s,<,\n<,g" | sed -e "s,>,: ,g" | egrep "<count|<due_reports"| tr -d '<' | tac)
    fi

	rm -f "$request"

	printf "Requesting missing reports...\n"

	if [[ $(echo "$RESULT" | wc -l) -gt 1 ]];then
	    echo "${C_YELLOW}$RESULT${C_RESET}"
	else
	    echo "${C_GREEN}$RESULT${C_RESET}"
	fi
}

#
# TODO:
# test submit report - bsd
#
function submitReport {
    temp_report="/tmp/weekly_report_$TIMESTAMP.txt"
    soap_report="/tmp/soap_report_$TIMESTAMP.xml"
    option="N"

    printf "Freely edit your report and save & quit when done.\nYou'll be asked to confirm the submission.\n"
    read -n 1

    if [[ "$option" == "${option#[Yy]}" ]]; then
        cp $REPORT_FILE $temp_report
        $EDITOR $temp_report
        calculate_total_time $temp_report
        printf "\nThis is what you're sending.\n"
	    read -n 1 -p "Are you sure? [y/N] " option
    fi

    if [[ "$option" == "${option#[Yy]}" ]]; then
        printf "\n\nCancelling ...\n"
        exit $ERR_OTHER
    fi

    printf "\n\nSending ...\n"
    
	echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ws=\"$WS_REPORTS/\">
	   <soapenv:Header/>
	   <soapenv:Body>
	      <ws:submitReport>
	         <submitReportRequest>
	            <username>$LOGIN</username>
	            <password>$PASS</password>
	            <report_string>
	            $(cat $temp_report)
	            </report_string>
	         </submitReportRequest>
	      </ws:submitReport>
	   </soapenv:Body>
	</soapenv:Envelope>" > $soap_report

    if $DEBUG ; then
		cat $soap_report
	fi

	RESULT=$(httpPostFile $TT_WS_SR $soap_report text/xml |  sed -e 's,.*<info>\([^<]*\)</info>.*,\1,g' 2>/dev/null)
	
    if [[ "$RESULT" =~ ^"$RQ_ERR_AUTH" ]]; then
		echo "Please configure your password in the configuration file."
		exit $ERR_OTHER
	elif [[ "$RESULT" =~ ^"$RQ_SUCCESS" ]]; then
        printf "\nSubmission result: ${C_GREEN} $RESULT ${C_RESET}\n"
    else
        printf "\nSubmission result: ${C_RED} $RESULT ${C_RESET}\n"
    fi

    if [[ $SAVE_SENT_REPORTS == true ]]; then
        checkOrCreateDir $SENT_REPORTS_DIR
        cp $temp_report "$SENT_REPORTS_DIR/report_$(date +"%Y_%m_%d").txt" > /dev/null
        printf "\nReport saved to: $SENT_REPORTS_DIR\n"
    fi

	rm -f ${soap_report} > /dev/null
	rm -f ${temp_report} > /dev/null
}

function showCC {
    temp_cc="/tmp/showCC_$TIMESTAMP.xml"

	echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ws=\"$WS_CC\">
            <soapenv:Header/>
                <soapenv:Body>
                    <ws:exportCC/>
                </soapenv:Body>
        </soapenv:Envelope>" > $temp_cc


	RESULT=$(httpPostFile $TT_WS_CC $temp_cc text/xml)

    if [[ $IS_MAC = true ]]; then
        RESULT=$(echo "$RESULT" | sed -e $'s,<key>,\\\n<key>,g' | sed -e $'s,</key>,</key>\\\n,g' -e $'s,<task>,\\\n<task>\\\t,g' -e $'s,</task>,</task>\\\n,g' | egrep 'key|task' | cut -d '>' -f 2 | cut -d '<' -f 1)
    else
        RESULT=$(echo "$RESULT" | sed -e "s,<key>,\n<key>,g" | sed -e "s,</key>,</key>\n,g" -e "s,<task>,\n<task>\t,g" -e "s,</task>,</task>\n,g" | egrep "key|task" | cut -d ">" -f 2 | cut -d "<" -f 1)
    fi

	rm -f $temp_cc

    printf "Cost Centers\n\n"
	echo "$RESULT"
}

############
# MAIN
############

# ASSERTIONS

## COMPATIBILITY
parse_date="parse_date_gnu"
if [[ "$OSTYPE" == "darwin"* ]]; then
       IS_MAC=true
       parse_date="parse_date_bsd"
fi

## USERDATA
LOGIN=$(decode_base64 $USERNAME)
PASS=$(decode_base64 $PASSWORD)

if [[ "x"$LOGIN == "xCHANGE_ME" ]]; then
    echo "Please update the config file with your credentials."
    exit $ERR_AUTH
fi

# If no arguments are given, show_usage
if [[ -z $1 ]]; then
    show_usage
    exit $ERR_OTHER
fi

# OPTIONS
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
                            echo "This option depends on 'fzf'. Please install it first in order to use this option."
                            exit $ERR_OTHER
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
            rm -i -v $REPORT_FILE $START
            ;;
        m)
            showMissingReports
            ;;
        b)
            showCC
            ;;
        p)
            submitReport
            ;;
        d)
            remove_entries $OPTARG
            ;;
        w)
            calculate_total_time $REPORT_FILE
            ;;
        e)
            $EDITOR $REPORT_FILE
            ;;
        s)
            validate_empty_report
            cat $REPORT_FILE
            $DEBUG && echo "Report file path: $REPORT_FILE"
            ;;
        h)
            show_usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit $ERR_OTHER
            ;;
    esac
done
