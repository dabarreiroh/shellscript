#!/bin/bash
# Script used to check if a list of tickets presents activity (changes)
# Usage:
#			Monitoring.sh	<ticket_list>
# Where:
#	- <ticket_list> 	A .csv file containing the tickets to be checked.
#						The file must have only one ticket per line.
#						Each line must have:
#							1- Ticket_ID
#							2- Country
#							3- URL
#						The file must not have a header line.
#
#----------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------------
#	Functionality:
#		1- Check if a folder for storing log files of checked tickets exist. If not, create it.
#		2- Read the input file line by line and extract the information of the ticket.
#		3- Check if the ticket has a log file (i.e. checked at least once before).
#			IF NOT:
#			> Create a log file Ticket_ID.txt
#			> Call the script get_url.sh with the URL and log file as arguments.
#				* Always try with proxy.
#				  Plus two checks:
#					* Try with mobile user agent
#					* Try without mobile user agent
#					* Depending on if the html response differs, decide which one will be the definitive log file.
#			> Continue to the next ticket.
#			
#			IF YES:
#			> Create a temporal log file
#			> Check the URL again, same as before (two checks, both with proxy, one with and one without user-agent).
#		4- Compare the log file with the temporal for changes.
#			> I.P.
#			> HTTP
#			> Title
#			> HTML Content
#		5- If the website presents changes in any of its fields, send it to review.
#			
#----------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------------
#	CHANGELOG
#----------------------------------------------------------------------------------------------------------------------------
#
#	From v1.0 to v1.1									2018-10-22	16:00:00	Deyvit Hernandez
#		- Section that compared both old and new log files extracted and now it's a function.
#		+ New function that handles the decisions for checking the curl calls implemented.
#		- Removed all the repeated code from the script.
#		- How to select the user-agent or no-user-agent log file needs testing/improving.
#		+ Addressed some special cases when comparing the data of the log files.
#			> When the new I.P. is null, no alert will be issued.
#			> When the new title is null, no alert will be issued.
#		+ Different levels of threat for different data changes set.
#			> IP change value of 3
#			> HTTP change value of 2
#			> Title change value of 1
#			> HTML change value from 1 to 3
#		- Updated the Functionality description of the script to reflect the changes.
#		! A lot more testing is needed.
#		! HOW TO HANDLE VARIOUS PROCESSES RUNNING AT THE SAME TIME AND NOT OVERWRITING THEMSELVES (Alerts-wise)
#
#
#	From v0.2 to v1.0									2018-10-16	17:30:00	Deyvit Hernandez
#		- Extraction of the HTML Code from the log files completed.
#		+ Comparison between the old and new data from the Website completed.
#			+ Comparison for IP, Website Title, HTTP Code completed.
#				! More testing for the previous data comparison is needed, specially for singular cases.
#			+ Comparison between HTML codes completed.
#				* Simpple numeric rule based on the ratio between different lines for each file implemented.
#		- Assignation of threat levels for each data changed completed.
#			! Different levels of threat depending on the data changed needs improving. Right now all changes have an equal
#			  threat level of 1.
#		- Clean up of temporal files at the end of teh script.
#		- Left commented the clean up of temporal log file for debugging.
#		! Decision tree for curl calls still pending.
#			* Function that handles this started.
#
#	From v0.1 to v0.2									2018-10-15	16:30:00	Deyvit Hernandez
#		- Completed the comments of the functionality of the script.
#		- Modified some of the messages displayed when testing a website for the first time.
#		- Section that checks previously checked tickets expanded:
#			> Extraction of flags from previous check completed.
#			> Extraction of information from previous check completed.
#			> curl call for a new log file, using flags extracted, completed.
#			> Extraction of new information from new log file completed.
#			! Comparison of the old and new information not done yet.
#		! Decision tree for curl calls not done yet.
#		- Several commented lines added for description and separation of sections.
#		? The decision tree for testing a website might be separated in a function if too much code is repeated.
#
#
#	From v0 to v0.1										2018-10-13	18:30:00	Deyvit Hernandez
#		- Section that checks previously checked tickets started.
#		- Extraction of proxy and user-agent flags tested and successful.
#		- Usage of flags extracted tested and successful.
#		- Extraction of other information extended.
#		- HTML response extraction not tested.
#
#
#	Version 0											2018-10-13	13:00:00	Deyvit Hernandez
#		- Removes the HTMLS folder to speed up testing.
#		- Only checks once the connection, and depending on the curl exit codes prints a message.
#		- Extracting the information from the csv file tested and successful.
#		- Only checks new tickets.
#
#----------------------------------------------------------------------------------------------------------------------------

trace=false

while getopts v options; do													# getopts loop
	case "${options}" in
				v)
					trace=true
				;;
	esac
done

shift "$((OPTIND-1))"														# Discard the options and sentinel --

usage() {
	echo "Usage: $0 [ options ] <tickets_file>" >&2						# Echo usage string to standard error
	exit 1
}

#----------------------------------------------------------------------------------------------------------------------------
compare_urls() {
# Internal function for handling log files comparison
# Usage:
#			compare_url		<file_1>	<file_2>
#	This function compares two log files obtained from the get_url script.
#	For this comparison, read the following information from both log files:
#		> curl exit code
#		> Domain IP
#		> HTTP Code
#		> Website Title
#		> HTML response
#
#	Compare both old (file 1) and new (file 2) information for changes in the website.
#	Store the changes in a global array for external usage.
#-------------------------------------------------------#
# Extract file 1 information.							#
#-------------------------------------------------------#	
#	declare -a -g alert_array
#	local html_start html_end
#	local f1_code f1_ip f1_http f1_title f1_html
#	local f2_code f2_ip f2_http f2_title f2_html
	
	f1_code=$( grep "Exit-Code:" $1 | cut -d ' ' -f2 )					# Extract the curl exit code
	f1_ip=$( grep "IP:" $1 | cut -d ' ' -f2 )							# Extract the domain IP
	f1_http=$( grep "HTTP-Code:" $1 | cut -d ' ' -f2 )					# Extract the http code
	f1_title=$( grep "Title:" $1 | cut -d ' ' -f2 )						# Extract the Website Title
	html_start=$( grep -n "<html" $1 | head -1 | cut -d: -f1 )			# Extract the Website HTML
	html_end=$( grep -n "</html>" $1 | cut -d: -f1 )					# Find the start <html> and end </html>
	if [[ -z $html_end ]]; then											 
		html_end=$(cat $1 | awk 'END {print NR-7}')						 
	fi
	if [[ -z $html_start ]]; then										# and extract the corresponding lines
		f1_html="No HTML in file"										# If no html is found, fill the variable
	else																# with a simple yet meaningful string
		f1_html=$( sed -n "$html_start,$html_end p" $1 )
	fi

#-------------------------------------------------------#
# Extract file 2 information.							#
#-------------------------------------------------------#
	f2_code=$( grep "Exit-Code:" $2 | cut -d ' ' -f2 )					# Extract the curl exit code
	f2_ip=$( grep "IP:" $2 | cut -d ' ' -f2 )							# Extract the domain IP
	f2_http=$( grep "HTTP-Code:" $2 | cut -d ' ' -f2 )					# Extract the http code
	f2_title=$( grep "Title:" $2 | cut -d ' ' -f2 )						# Extract the Website Title
	html_start=$( grep -n "<html" $2 | head -1 | cut -d: -f1 )			# Extract the Website HTML
	html_end=$( grep -n "</html>" $2 | cut -d: -f1 )					# Find the start <html> and end </html>
	if [[ -z $html_end ]]; then											 
		html_end=$(cat $2 | awk 'END {print NR-7}')						 
	fi
	if [[ -z $html_start ]]; then										# and extract the corresponding lines
		f2_html="No HTML in file"										# If no html is found, fill the variable
	else																# with a simple yet meaningful string
		f2_html=$( sed -n "$html_start,$html_end p" $2 )
	fi
	
#-------------------------------------------------------#
# Print file 1 vs file 2 info.							#
#-------------------------------------------------------#
	if $trace; then
		echo -e "DATA\tFile 1\tFile 2"
		echo -e "IP:\t$f1_ip\t$f2_ip"
		echo -e "HTTP:\t$f1_http\t$f2_http"
		echo -e "TITLE:\t$f1_title\t$f2_title"
	fi
#-------------------------------------------------------#
# Compare both files data.								#
#-------------------------------------------------------#
		
	if [[ "$f1_ip" != "$f2_ip" ]]; then									# Check if both IPs are equal
		alert_array[0]=3												# If the IP changed, raise its flag
	else
		alert_array[0]=0
	fi
	if [[ "$f1_http" != "$f2_http" ]] && ! [[ "$f1_http" == "000" && $f2_http -ge 500 ]] && ! [[ "$f2_http" == "000" && $f1_http -ge 500 ]]; then
		alert_array[1]=2												# Check if both HTTP code responses are equal
    else																# If the HTTP code changed, but not from
    	alert_array[1]=0												# (000 to 500+) or (500+ to 000), raise its flag
    fi
    if [[ "$f1_title" != "$f2_title" ]]; then
    	alert_array[2]=1												# Check if both Website Titles are equal
    else																# If the Title changed, raise its flag
    	alert_array[2]=0
    fi
		
# Time to compare the HTML Code
# This step is done with the command 'diff'.
#	- Option -B, --ignore-blank-lines makes 'diff' ignore blank lines when calculating differences.
#	- Option -b, --ignore-space-change makes 'diff' ignore any changes which only change the amount of whitespace.
#	- Option -i, --ignore-case makes 'diff' ignore case differences in file contents.
#	- Option --suppress-common-lines makes 'diff' not output lines common betwen the two files.
#	- Option -I, --ignore-matching-lines=RE makes 'diff' ignore changes whose lines all match regular expression RE.
#
# After passing through the diff command, print only the lines that start with '>' or '<'. This essentialy removes
# the '---' separator and line-modification expression that diff outputs (sed command).
# Then, count how many different lines each file has (awk command), old file (<) and new file (>).
		
	local temp_f1_html="HTMLS/tempf1.html"								# 2 temporal files for storing the html codes
    local temp_f2_html="HTMLS/tempf2.html"
	
	echo "$f1_html" > "$temp_f1_html"										# Store the HTML code in the temporal files
	echo "$f2_html" > "$temp_f2_html"
		
	local temp=$(diff --ignore-blank-lines --ignore-space-change --ignore-case \
		 --suppress-common-lines $temp_f1_html $temp_f2_html | \
		sed -r -n -e '/^[^0-9-].*$/p' | awk '/^>/{a++}; /^</{b++}END{print a; print b}')
	
	local new_lines=$( echo $temp | cut -d ' ' -f1 )
	local old_lines=$( echo $temp | cut -d ' ' -f2 )
		
# The rules to determine if two HTML codes are different are quite complex, and vary from client to client.
# For this reason, a simplified rule based on the amount of lines changed for each file is used.
# Numeric rule used...
#	- If more than twice lines are different in the first file than in the second -> ALERT	(HTML expansion)
#	- If more than a 100 lines are different between both files -> ALERT					(HTML change)
#	- If more than twice lines are different in the second file than in the first -> ALERT	(HTML reduction)
		
	if (( new_lines > 2 * old_lines )); then
		alert_array[3]=3
	elif (( new_lines + old_lines > 100 )); then
		alert_array[3]=2
	elif (( 2 * new_lines < old_lines )); then
		alert_array[3]=1
	else
		alert_array[3]=0
	fi
	
	rm -f $temp_f1_html
	rm -f $temp_f2_html
}
#----------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------------
check_url() {
# Internal function for handling url checks
# Usage:
#			check_url	<url>	<country>	<output_file>
#
#	The url check is always with proxy.
#		1- First attempt is with oxylabs.
#		2- If oxylabs failed, try again.
#		3- If oxylabs definitely won't connect, try with proxy from database.
#		4- If no proxy found in database, or definitely failed... then what?
#	With the proxy used, two different checks are performed.
#		1- Without user-agent.
#		2- With user-agent.
#	Then both files are compared against each other.
#		> IF BOTH ARE EQUAL... then no user-agent required.
#		> IF NOT EQUAL... then maybe the user-agent is needed.
#	Store the log file selected in the output_file	
#-------------------------------------------------------#
# Local variables definition.							#
#-------------------------------------------------------#
	local attempt=0
	local retry=true
	
	local log_user="HTMLS/log_user.html"
	local log_no_user="HTMLS/log_no_user.html"
	
	local proxy='-o'
	local code=0
	
# For the next two steps, various attempts might be needed due to the possibility of not getting a response from the URL.
#	  Expected exit codes:
#		 0	-> No errors.
#		 1	-> Unsupported protocol. Error in proxy/URL
#		 3	-> URL malformed.
#		 5	-> Couldn't resolve proxy. time_connect > 130 otherwise exit code 28.
#		 6	-> Couldn't resolve host.
#		 7	-> Failed to connect to the host. time_connect > 130 otherwise exit code 28.
#		22	-> HTTP Page not retrieved. Requested URL was not found or returned HTTP code 400+.
#			   curl option -f, --fail must be used for it to appear.
#		28	-> Operation timeout.
#		35	-> TLS/SSL connect error.
#		43	-> Should never appear. If it does, file a bug report to curl authors.
#		47	-> Too many redirects. Max=10 by default. Change limit with --max-redirs option.
#		52	-> Server didn't reply anything.
#		56	-> Complex error. But in this case, probably oxylabs failed.
#		67	-> User name, password, or similar was not accepted and failed to log in.
	
#-------------------------------------------------------#
# Check URL without user-agent.							#
#-------------------------------------------------------#
	while $retry; do
		attempt=$((attempt+1))											# Attempt counter increment
		bash get_url.sh -v -r 4 $proxy $2 $1 $log_no_user					# Call get_url script, with proxy
		code=$( grep "Exit-Code:" $log_no_user | cut -d ' ' -f2 )		# Extract the curl exit code
		
		case $code in
				0|1|3|6|47|52|67)										# Successful (0) / Can't do or try anything (others)
					retry=false											# No need to keep trying
					;;
				5|7|28|35|56)											# Couldn't connect in the allowed time/
					retry=true											# Keep trying...
					;;
				22)
					http=$( grep "HTTP-Code:" $log_no_user | cut -d ' ' -f2 )
					if [[ "$http" = "000" ]] || [[ $http -ge 500 ]]; then
						retry=true
					else
						retry=false
					fi
					;;
				*)														# Just in case...
					retry=false
					;;
		esac
		
		case $attempt in											# If n-th attempt, then in the next attempt...
					1)												#	1- Try with oxylabs
						proxy='-o'									#	2- Try again but with proxy from database
						;;											#	3- Then nothing else to do... stop trying
					2)
						proxy='-p'
						;;
					3)
						retry=false
						;;
		esac
		
	done

#-------------------------------------------------------#
# Check URL with user-agent.							#
#-------------------------------------------------------#
	
	retry=true
	attempt=0
	proxy='-o'
	
	while $retry; do
		attempt=$((attempt+1))											# Attempt counter increment
		bash get_url.sh -v -r 4 $proxy $2 -u "ANDROID" $1 $log_user		# Call get_url script, with proxy and user-agent
		code=$( grep "Exit-Code:" $log_user | cut -d ' ' -f2 )			# Extract the curl exit code
		
		case $code in
				0|1|3|6|47|52|67)										# Successful (0) / Can't do or try anything (others)
					retry=false											# No need to keep trying
					;;
				5|7|28|35|56)											# Couldn't connect in the allowed time/
					retry=true											# Keep trying...
					;;
				22)
					http=$( grep "HTTP-Code:" $log_no_user | cut -d ' ' -f2 )
					if [[ "$http" = "000" ]] || [[ $http -ge 500 ]]; then
						retry=true
					else
						retry=false
					fi
					;;
				*)														# Just in case...
					retry=false
					;;
		esac
		
		case $attempt in											# If n-th attempt, then in the next attempt...
					1)												#	1- Try with oxylabs
						proxy='-o'									#	2- Try again but with proxy from database
						;;											#	3- Then nothing else to do... stop trying
					2)
						proxy='-p'
						;;
					3)
						retry=false
						;;
		esac
		
	done
	
#-------------------------------------------------------#
# Compare both log files data.							#
#-------------------------------------------------------#
	
	compare_urls $log_no_user $log_user
	
#-------------------------------------------------------#
# Select which log_file to use.							#
#-------------------------------------------------------#
	
#	printf '%s\n' "${alert_array[*]}"
	
	local difference=0													# How different are both log files from each other
	for i in ${alert_array[@]}; do
		let difference+=$i
	done
	
    if [[ $difference -eq 0 ]]; then									# If both files are the same,
    	cat $log_no_user > $3											# Then store the no-user-agent log file
#		echo "No difference between with and without user-agent."
	else																# Otherwise
		cat $log_user > $3												# Store the user-agent log file
#		echo "Difference between with and without user-agent."
    fi
	
#-------------------------------------------------------#
# Clean up the unnecessary files.						#
#-------------------------------------------------------#
	rm -f $log_user
	rm -f $log_no_user
}
#----------------------------------------------------------------------------------------------------------------------------

#############################################################################################################################
#	BEGIN SCRIPT
#############################################################################################################################

time=$(date +"%Y-%m-%d %T")												# Fetch time of review (YY-MM-dd HH:MM:SS)

alerts_file="ChangeStatus.csv"											# File where alerts are stored
echo "Ticket ID,Country,URL,Threat Level" > $alerts_file

#----------------------------------------------------------------------------------------------------------------------------
# rm -rf HTMLS															# For testing only. DON'T FORGET TO REMOVE/COMMENT
#----------------------------------------------------------------------------------------------------------------------------
# This section is obsolete after first run
if [ ! -d HTMLS ]; then													# Check if the folder for storing log files exists.
    mkdir -p HTMLS														# If not, create it.
fi
#----------------------------------------------------------------------------------------------------------------------------

while read -r line; do													# Read the file.
																		# Extract the ticket information:
	ticket_id=$( echo "$line" | cut -d, -f1)							#	- Ticket ID
	ticket_country=$( echo "$line" | cut -d, -f2)						#	- Ticket country
	ticket_url=$( echo "$line" | cut -d, -f3)							#	- Ticket URL
	log_file="HTMLS/$ticket_id.html"									#	- "Create" a log file for the ticket
	if $trace; then
		echo "$ticket_id"
	fi
#----------------------------------------------------------------------------------------------------------------------------
#		Check if the ticket has not been checked before
#		If it hasn't been checked before:
#		FILL THE LOG FILE & CONTINUE...
#----------------------------------------------------------------------------------------------------------------------------
	if [[ ! -f "$log_file" ]]; then
		if $trace; then
			echo "First check..."
		fi
		check_url "$ticket_url" "$ticket_country" "$log_file"
		if $trace; then
			echo "Done"
		fi
#----------------------------------------------------------------------------------------------------------------------------
# If it has been checked before:
#		FILL A NEW LOG FILE & COMPARE...
#		THEN DECIDE IF AN ALERT SHOULD BE ISSUED!
#----------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------#
# Extract the flags information.						#
#-------------------------------------------------------#
	
	else
		if $trace; then
			echo "Review in progress..."
		fi
		user_flag=$( grep "User-Agent:" "$log_file" | cut -d ' ' -f2 )	# Extract the user-agent flag
		if [[ $user_flag != "NONE" ]]; then								# String formating for user-agent flag...
			user_flag="-u $user_flag"									# If a user-agent was used:
		else															#	- Activate the user-agent option (-u)
			user_flag=""												#	- Add the device used
		fi																# Else... do nothing (empty string)
		
#-------------------------------------------------------#
# New curl call to the website.							#
#-------------------------------------------------------#
		if $trace; then
			echo "New check..."
		fi
		temp_file="HTMLS/$ticket_id-temp.html"							# "Create" a temporal file
		check_url "$ticket_url" "$ticket_country" "$temp_file"
		if $trace; then
			echo "Done"
		fi
#-------------------------------------------------------#
# Compare both new and old data.						#
#-------------------------------------------------------#
		if $trace; then
			echo "Changes..."
		fi
		compare_urls "$log_file" "$temp_file"
		if $trace; then
			echo "Done"
		fi
#-------------------------------------------------------#
# Check if the ticket should be sent for review.		#
#-------------------------------------------------------#
		if $trace; then
			echo "I-H-T-C"
			printf '%s\n' "${alert_array[*]}"
		fi
		
		threat=0														# Threat level of reactivation for the ticket
		for i in ${alert_array[@]}; do
			let threat+=$i
		done
		
    	if [[ $threat -gt 0 ]]; then
    		echo $ticket_id,$ticket_country,$ticket_url,$threat >> $alerts_file
#			echo "Ticket sent for review. Threat level of $threat"
    	fi
		
		rm -f $temp_file												# Clean up the temporal log file
																		# Uncomment for debugging
	fi
	if $trace; then
		echo "-------------------"
	fi
done < "$1"
