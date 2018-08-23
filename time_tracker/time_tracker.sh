#!/bin/bash

#SCRIPT
SCRIPT_DIR=$(dirname $0)
SCRIPT_NAME=$(basename $0 .sh)
CONFIG="$(dirname $0)/.config"
MAIN_OPTS="aV:v:rdweshmbp"
ADD_OPTS="t:f:ixl"

#EXTERNAL BUSINESS TAGS
COST_CENTERS="$SCRIPT_DIR/.cost_centers"
CUSTOMERS="$SCRIPT_DIR/.customers"
PROJECTS="$SCRIPT_DIR/.projects"
TAGS="$SCRIPT_DIR/.tags"

#CONSTANTS
DEBUG=false
EPOCH="19700101"
NOW="now"
TIMESTAMP=$(date +%s)
INTERACTIVE_TAGS="INTERACTIVE_TAGS"
HEADER_REGEX="^\w*\s[\/\(\)[:digit:]]+$"
ENTRY_REGEX="^[[:digit:]\:\t]+[\w[:blank:]]+"
EDITOR=${EDITOR:-vim}

#From this script will come custom configurations used to complete the report
source $CONFIG

#FILE OPTIONS
REPORT_FILE=$REPORT_DIR/$REPORT_FILENAME
START=$REPORT_DIR/.start

##############
# FUNCTIONS
##############

function show_usage(){
    printf "Application to report time entries of working tasks.\nTask details are written when the task is finished.

Usage: $(basename $0) [-h] [-a [-f time] [-t \"tag name\"] [-i] [-l] [-x]]
                        [-s] [-e] [-w] [-v day] [-V monday] [-p] [-m] [-b] [-r]

Options:

-a	add a time entry now (a report entry is made of two time entries)
-f	with -a, force a time entry. Format = %%H:%%M
-t	with -a, add a task name instead of the default one
-i	with -a, interactively choose every business tag
-l	with -a, logoff computer after reporting
-x	with -a, turn off the screen after reporting
-v	add a vacation entry for the given day. Format = %%Y-%%m-%%d
-V	add a vacation entry for a week. any given Monday. Format = %%Y-%%m-%%d
-s	show report
-e	edit report file manually
-w	calculate total working time in the report
-p	post report to server
-m	get missing reports from server
-b	get business tags from server
-r	remove temp and report files
-h	this help menu\\n"
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

# POSIX parse date function
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
		exit
	fi
}

function assert_valid_hour(){
    assert_not_empty "$1" "No valid hour was given."

    #Parse hour using date
    hour_parsed=$($parse_date "%H:%M" $1)

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
    day_parsed=$($parse_date "%F" $1)

    if [[ "$day_parsed" != "$day" ]]; then
        echo "$1 is NOT a valid YYYY-MM-DD date"
        exit
    fi
}

function assert_valid_monday(){
    #Get weekday
    weekday=$($parse_date "%u" "$1")

    if [[ $weekday != "1" ]]; then
		echo -e "$1 is NOT a Monday => $($parse_date "" $1)\nIn order to add a full holiweek insert the corresponding Monday.\n"
		exit
	fi
}

#Input: "01:10"
#Output: 4200
function get_seconds(){
	#replace ':' for a space and remove leading zeros
	read -r h m <<< $(echo "$1" | tr ':' ' ' | sed -E 's,0([0-9])+,\1,g')
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

	done < "$REPORT_FILE"

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
		next_day=$($parse_date "%F" "$1" "$i")
		register_holiday $next_day
	done
}

function register_holiday() {
   assert_valid_date $1

	echo -e "\n$($parse_date "%A (%d/%m/%Y)" $1)" >> $REPORT_FILE
	printf "$HOLIDAY_ENTRY_START\\t$HOLIDAY_ENTRY_STOP\\t$COST_CENTER_H\\t$CUSTOMER_NAME_H\\t$PROJECT_NAME_H\\t$TASK_H\\n" >> $REPORT_FILE
	echo -e "\nHoliday Task \"$TASK_H\" added for day $1\n\n$(tail -2 $REPORT_FILE)"
}

function register_time_entry() {
    #Set default time entry as 'now'
    time_entry=$($parse_date "%H:%M")

    if [[ $1 != $NOW ]]; then
		time_entry=$($parse_date "%H:%M" $1)
	fi

    assert_valid_hour $time_entry

	if [[ -e $START ]]; then

        #Check for TASK only if we're writing it...
        if [[ $2 = $INTERACTIVE_TAGS ]]; then
            COST_CENTER=$(cat $COST_CENTERS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle)
            CUSTOMER_NAME=$(cat $CUSTOMERS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle)
            PROJECT_NAME=$(cat $PROJECTS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle)
            TASK=$(cat $TAGS | sed 's/^#.*//g' | sed '/^\s*$/d' | fzf --tac --cycle --print-query | tr -d '\n')

        elif [[ ! -z "$2" ]]; then
            TASK="$2"
        fi

		rm $START

        # if subtraction is negative, means a day has passed.
        entry_start=$(get_seconds "$(tail -1 $REPORT_FILE | tr -d '\t')")
		entry_stop=$(get_seconds "$time_entry")
		entry_diff=$((entry_stop - entry_start))

        if [[ $entry_diff -lt 0 ]]; then

            #end task for the day
            printf "23:59\t" >> $REPORT_FILE
		    printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\n" >> $REPORT_FILE

		    #add header for new day
		    echo -e "\n$($parse_date $"%A (%d/%m/%Y)")" >> $REPORT_FILE

		    #start new task
		    printf "00:01\t" >> $REPORT_FILE

		    #show four lines instead of one
		    lines="-4"
		    echo $lines
        fi

        #end task and append biz tags
		printf "$time_entry\t" >> $REPORT_FILE
		printf "$COST_CENTER\t$CUSTOMER_NAME\t$PROJECT_NAME\t$TASK\t\n" >> $REPORT_FILE
		echo -e "Task $TASK finished\n\n$(tail ${lines:-"-1"} $REPORT_FILE)"
	else
		#Grep the current day in the report file
		[[ -e $REPORT_FILE ]] && grep -Fq $($parse_date "%d/%m/%Y") $REPORT_FILE
		is_new_day=$?
		if [ "$is_new_day" -ne 0 ]; then
			echo -e "\n$($parse_date $"%A (%d/%m/%Y)")" >> $REPORT_FILE
		fi
		printf "$time_entry\t" >> $REPORT_FILE
		touch $START
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
        RESULT=$(echo $RESULT | sed -e $'s,<,\\\n<,g' | sed -e $'s,>,: g' | egrep "<count|<due_reports"| tr -d '<' | tail -r)
    else
        RESULT=$(echo $RESULT | sed -e "s,<,\n<,g" | sed -e "s,>,: ,g" | egrep "<count|<due_reports"| tr -d '<' | tac)
    fi

	rm -f "$request"

	echo -e "Requesting missing reports...\n"
	echo "$RESULT"
}

#
# TODO:
# test submit report - gnu & bsd
#
function submitReport {
    temp_report="/tmp/weekly_report_$TIMESTAMP.txt"
    soap_report="/tmp/soap_report_$TIMESTAMP.xml"
    option="N"

    echo "Now freely edit your report and leave what you want to send... Save the file."
    read -n 1

    while [[ "$option" == "${option#[Yy]}" ]]; do

        cp $REPORT_FILE $temp_report
        vim $temp_report
        cat $temp_report
        read -n 1 -p "This is what you're sending. Are you sure? [y/N] " option

    done

    echo -e "\n\nSending---"

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

	#RESULT=$(httpPostFile $TT_WS_SR $soap_report text/xml |  sed -e 's,.*<info>\([^<]*\)</info>.*,\1,g' 2>/dev/null)

    cat $soap_report
    
	echo -e "\nSubmission result: \e[00;31m$RESULT \e[00m"

	if [ "$RESULT" == "Authentication error!" ]; then
		echo "Please configure your password in the configuration file."
	fi

    if [[ $SAVE_SENT_REPORTS == true ]]; then
        checkOrCreateDir $SENT_REPORTS_DIR
        cp $temp_report "$SENT_REPORTS_DIR/report_$(date +"%Y_%m_%d").txt" > /dev/null
        echo -e "\nReport saved to: $SENT_REPORTS_DIR"
    fi

	rm -f $soap_report > /dev/null
	rm -f $temp_report > /dev/null
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

    echo -e "Cost Centers\n"
	echo "$RESULT"
}

############
# MAIN
############

#ASSERTIONS

##COMPATIBILITY
parse_date="parse_date_gnu"
if [[ "$OSTYPE" == "darwin"* ]]; then
       IS_MAC=true
       parse_date="parse_date_bsd"
fi

##USERDATA
LOGIN=$(decode_base64 $USERNAME)
PASS=$(decode_base64 $PASSWORD)

if [[ "x"$LOGIN == "xCHANGE_ME" ]]; then
    echo "Please update the config file with your credentials."
    exit
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
            #should be the first argument
            DEBUG=true
            set -x
            ;;
        w)
            calculate_total_time
            ;;
        e)
            $EDITOR $REPORT_FILE
            ;;
        s)
            cat $REPORT_FILE
            echo -e "\n"
            $DEBUG && echo "Report file path: $REPORT_FILE"
            ;;
        h)
            show_usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
