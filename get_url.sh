#!/bin/bash
# Script to execute the curl command with specific settings.
# Usage:
#			get_url.sh [ options ] <url> <output_file>
# Where:
#	- <url> is the website URL/URI to be checked
#	- <output_file> is the file where the response is going to be saved.
#					The response will overwrite the file.
#					The file will contain:
#						> URL
#						> Domain IP
#						> Proxy needed?
#						> User agent?
#						> Header(s)
#							- More than one if there are redirections
#						> HTML response
#						> HTTP code
#						> curl exit code + explanation
#						> Website Title
#						> Date of review
#
# The options that can be activated are:
#
#	-o <country>			Try with a proxy from the respective <country>.
#							In this case the proxy is from oxylabs.
#							If -o and -p are specified at the same time, the last one written will be used.
#
#	-p <country>			Try with a proxy from the respective <country>.
#							In this case the proxy is from a list of preloaded proxies.
#							The list of proxies is in the file "proxies.txt"
#							This file has to be updated periodically.
#							If -o and -p are specified at the same time, the last one written will be used.
#
#	-c						Try with a custom proxy. Protocol, IP and Port have to be specified during run time.
#								- The protocol has to be http, socks4 or socks5.
#								- The IP has to be valid (4 numbers separated by a dot, each number with 1 to 3 digits, and
#								  no greatter than 255)
#
#	-u <device>				Try with a personalized user-agent. Can be Android, iOS, Mozilla-PC or Chrome-PC.
#							<device> is case insensitive.
#							The device can be modified in the getopts loop -> u option
#
#	-t <seconds>			Maximum time the connection to the server may take.
#							If not specified, defaults to 5 seconds
#
#	-T <seconds>			Maximum time the whole operation may take.
#							If not specified, defaults to 20 seconds.
#
#	-r <number>				Maximum number of redirections to follow.
#							If not specified, defaults to 10.
#
#	-v						Verbose active for curl. Usefull for debugging.
#
#----------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------------
#	CHANGELOG
#----------------------------------------------------------------------------------------------------------------------------
#
#	From v2.1.0 to v2.1.1								2018-10-23	01:00:00	Deyvit Hernandez
#		- Fixed a bug in which the flag evaluations weren't working properly.
#		- Added an extra confirmation for the port provided when using a [custom proxy]
#		! Option -c [custom proxy] hasn't been tested yet.
#
#
#	From v2.0.0 to v2.1.0								2018-10-19	17:00:00	Deyvit Hernandez
#		- The script now prints the meaning of the expected exit-codes for the curl call.
#		- The curl call now has a limit of 10 redirections to be followed.
#			* Because of the instability of oxylabs, when a URL redirects indefinitely, the connection usually gets lost
#			  during the connection attempts before reaching the default maximum number of redirections (50), and by far,
#			  usually failing in the 13th attempt. This results in an exit code of 28 (time-out), instead of 47.
#		- New option -r [max-redirs] to modify the maximum number of redirections to be followed.
#		- Added to the usage section the option -r for setting the maximum number of redirections to be followed.
#		- Updated the description of "BEGIN SCRIPT" section with the usage of option --max-redirs in curl calls.
#		- Optimized the usage of flags. Before a string comparison was used, now boolean values (true/false) are evaluated.
#		- Fixed a bug in which the custom_flag wasn't evaluated properly.
#		! Option -c [custom proxy] hasn't been tested yet.
#
#
#	From v1.4.2 to v2.0.0								2018-10-17	16:00:00	Deyvit Hernandez
#		- Implemented the option -c [custom proxy].
#			! Needs testing.
#			- Previously, the usage section specified that the custom proxy option needed an argument; now the option asks
#			  for the protocol, proxy ip and port during run time.
#			- Usage section updated to reflect this change.
#			! Only works with proxy IPs, not servers, like oxylabs.
#			! If the proxy needs user+password, won't work either.
#
#	From v1.4.1 to v1.4.2								2018-10-17	14:40:00	Deyvit Hernandez
#		- Now the Date of review is added at the end of the output file.
#
#
#	From v1.4 to v1.4.1									2018-10-13	12:30:00	Deyvit Hernandez
#		- Now the Website Title is added at the end of the output file.
#
#
#	From v1.3 to v1.4									2018-10-10	00:15:00	Deyvit Hernandez
#		- Now the URL is attached at the start of the output file.
#		- Now a flag stating if a custom user-agent was used to check the URL, and which one, is attached to the output file.
#		- Now a flag stating if a proxy was used to check the URL is attached to the output file.
#		- curl outputs changed from single '>' to double '>' due to the previous change.
#		- A random string is attached at the end of the URL always; previously it was only used when checking with proxy.
#		- Reorganized the declaration of the variables used for no-cache requests.
#		- Fixed a bug in which the header was passed a random string instead of the no-cache command when using proxy.
#		- Now the device variable defaults to NONE (Only used for printing the proxy flag).
#		- Fixed the known bug of wrong remote IP printed to output file when using proxy:
#			* curl no longer handles this.
#			* a dig command is used to fetch the URL (domain) IP.
#		- Now the URL's domain IP address is attached at the start of the output file, below the URL.
#		- Updated the comments of the script to display the changes above.
#		- Changed the format of the line [Exit Code] to [Exit-Code].
#		- Changed the position of --verbose option in curl call. Previous position altered the desired output.
#
#
#	From v1.2 to v1.3									2018-10-08	02:30:00	Deyvit Hernandez
#		- Changed the option -m [mobile user agent] to -u [user agent] to expand the option.
#		- Option -u [user agent] now allows to set Mozilla and Chrome user agents.
#		- Now curl always sends non-cached requests when not using proxy.
#		- To overcome the cache limitations when using proxy, now a random string is added at the end of the URL ("?####").
#		- The "no cache" functionality needs testing.
#		KNOW BUG(S)
#		* When using proxy, the remote IP written to the output file is the proxy IP, not the URL IP.
#
#
#	From v1.1 to v1.2									2018-10-05	19:00:00	Deyvit Hernandez
#		- Changed the letters of some options:
#			* -p [oxylabs proxy] is now -o
#			* -x [proxy from database] is now -p
#			* -P [custom proxy] is now -c
#		- Added comments for the option -c [custom proxy] for future reference.
#		- Changed "settings" to "options" in the usage comments.
#		- Aumented the indentation of comments for better visualization.
#		- Changed the notes in the "Checking with proxy" section.
#		- Removed the fixed proxy for the option [proxy from database].
#		- Now the option [proxy from database] fetchs a proxy from the file "proxies.txt".
#		- If there is no proxy from the specified country in the database, script will end with exit code 3.
#		- The functionality of fetching proxies from database can be made into another script if the modularity is needed.
#		- The message error for "no proxy found in database" can/should be redirected to an error file.
#		- The output file now also stores the headers. Added the functionality to its description.
#		- curl calls now always have the --include option activated (for the sake of the last change).
#		- Added a "@" to the pattern when fetching the proxy from database for differentiation.
#		- Commented the two echo's specifying the url and if a proxy is used.
#		- The argument for the write-out option of curl is now a variable, between BEGIN SCRIPT and CHECKING WITH PROXY.
#		- Modified the write-out argument of curl for better logging.
#
#
#	From v1 to v1.1										2018-10-05	13:00:00	Deyvit Hernandez
#		- Simplified the section for selecting the proxy to be used. Now depending on the option a proxy string is created
#		  and used in the curl call.
#		- Changed the way the output file is written from [attached at the end] to [overwrite].
#		- The fields for option -P [custom proxy] have been placed in the script as comments. Still not implemented.
#		- A fixed proxy is used when selecting a proxy from database (option -x) for testing purposes.
#		- Removed many echo's from the script.
#		- echo's now specify the URL being checked, and if a proxy is used, its country.
#		- Reorganized the curl calls.
#		- Added option -v to script, which activates the verbose option in curl calls.
#		- Removed the verbose option in the curl calls, and changed the comment about it.
#		- Fixed the comments about options -p and -x being mutually exclusive.
#		- Completed the description of the output file at the start of the script.
#		- Indentation of the comments explaining the options available for the script fixed. 
#		- Exit code of curl is now attached at the end of the output file.
#		- Notes added for the testing of the connection to a proxy.
#
#----------------------------------------------------------------------------------------------------------------------------

oxylab_flag=false
proxy_flag=false
custom_flag=false
proxy=""
country=""
mobile_flag=false
device="NONE"
user_agent=""
time_connect=5
time_max=20
max_redir=10
verbose=""

usage() {
	echo "Usage: $0 [ options ] <url> <output_file>" >&2					# Echo usage string to standard error
	exit 1
}

valid_ip() {																# Function for checking a valid IP
	local  ip=$1															# Define local variable ip
	local  stat=1															# Define local variable stat

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then	# Check if IP consists of 4 numbers, separated
		OIFS=$IFS															# by a dot, and no longer than 3 digits
		IFS='.'
		ip=($ip)															# Separate the 4 numbers into an array
		IFS=$OIFS
																			# Check all numbers are lower or equal than 255
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
			&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?																# Save the result
    fi
    return $stat															# Return it
}

#----------------------------------------------------------------------------------------------------------------------------
#	  Expected exit codes:
#		 0	-> No errors.
#		 1	-> Unsopported protocol. Error in proxy/URL
#		 3	-> URL malformed.
#		 5	-> Couldn't resolve proxy. time_connect > 130 otherwise exit code 28.
#		 6	-> Couldn't resolve host.
#		 7	-> Failed to connect to the host. time_connect > 130 otherwise exit code 28.
#		22	-> HTTP Page not retrieved. Requested URL was not found or returned HTTP code 400+.
#			   curl option -f, --fail must be used for it to appear.
#		28	-> Operation timeout.
#		35	-> TLS/SSL connect error.
#		43	-> Should never appear. If it does, file a bug report to curl authors.
#		47	-> Too many redirects. Max=50 by default. Change limit with --max-redirs option.
#		52	-> Server didn't reply anything.
#		56	-> Complex error. But in this case, probably oxylabs failed.
#		67	-> User name, password, or similar was not accepted and failed to log in.
#----------------------------------------------------------------------------------------------------------------------------

exit_description() {														# Function for printing the meaning of the
																			# expected exit codes.
																			# Receives 2 arguments:
																			#	1- exit-code
																			#	2- output file
	case $1 in
			0)																# Successful curl call
				echo "Successful curl call." >> $2							# Nothing else to do here?
				;;
			1|3)															# Can't do or try anything. The URL is incorrect
				echo "Unsopported protocol or malformed URL." >> $2			# Nothing else to do here!
				;;
			5|7|28)															# Couldn't connect in the allowed time
				echo "Op. timeout | Proxy/Host not resolving." >> $2		# Try with/different proxy and/or user-agent
				;;
			47)																# Too many redirections
				echo "Too many redirections." >> $2							# Try with proxy or user-gent, or both
				;;
			6|52)															# Definitely won't connect
				echo "Definitely won't connect." >> $2						# Try with proxy? or user agent?
				;;
			67)																# Error in proxy user/password or URL needs them
				echo "Error in user/password." >> $2						# Try different proxy?
				;;
			22)
				echo "Error 400+." >> $2									# Try again?
				;;
			35)
				echo "TLS/SSL connect errorError 400+." >> $2				# Try again...
				;;
			*)																# Just in case...
				echo "Weird curl exit code" >> $2
				;;
	esac
}

while getopts o:p:cu:t:T:r:v options; do									# getopts loop
	case "${options}" in
				o)
					oxylab_flag=true										# Activate oxylab_flag
					proxy_flag=false										# Deactivate proxy_flag
					custom_flag=false										# Deactivate custom_flag
					country=${OPTARG}										# set the country for the proxy
					;;
				p)
					oxylab_flag=false										# Deactivate oxylab_flag
					proxy_flag=true											# Activate proxy_flag
					custom_flag=false										# Deactivate custom_flag
					country=${OPTARG}										# set the country for the proxy
					;;
				c)													
					oxylab_flag=false										# Deactivate oxylab_flag
					proxy_flag=false										# Deactivate proxy_flag
					custom_flag=true										# Activate custom_flag
					;;
				u)
					mobile_flag=true										# Activate mobile_flag
					device=${OPTARG}										# Set device
					device=${device^^}										# Upper case conversion
					case $device in
							ANDROID)										# User-Agent for Android (Samsung Note 5)
									user_agent='Mozilla/5.0 (Linux; Android 6.0.1; SAMSUNG SM-N920T Build/MMB29K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/44.0.2403.133 Mobile Safari/537.36'
									;;
							IOS)											# User-Agent for IOS (IPhone)
									user_agent='Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5'
									;;
							CHROME)
									user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36"
									;;
							FIREFOX)
									user_agent="Mozilla/5.0 (Windows NT 10.0; WOW64; rv:56.0) Gecko/20100101 Firefox/56.0"
					esac
					;;
				t)
					time_connect=${OPTARG}									# Set time_connect
					re_isnum='^[0-9]+$'										# regex to match whole numbers only
					if ! [[ $time_connect =~ $re_isnum ]]; then				# if time_connect is not a whole number...
						echo "Error: time_connect must be a positive, whole number. Default value (5) will be used." >&2
						time_connect=5
					elif [ $time_connect -eq "0" ]; then					# if it's zero...
						echo "Error: time_connect must be greater than zero. Default value (5) will be used." >&2
						time_connect=5
					fi
					;;
				T)
					time_max=${OPTARG}										# Set time_max
					re_isnum='^[0-9]+$'										# regex to match whole numbers only
					if ! [[ $time_max =~ $re_isnum ]]; then					# if time_max is not a whole number...
						echo "Error: time_max must be a positive, whole number. Default value (20) will be used." >&2
						time_max=20
					elif [ $time_max -eq "0" ]; then						# if it's zero...
						echo "Error: time_max must be greater than zero. Default value (20) will be used." >&2
						time_max=20
					fi
					;;
				r)
					max_redir=${OPTARG}										# Set max_redir
					re_isnum='^[0-9]+$'										# regex to match whole numbers only
					if ! [[ $time_max =~ $re_isnum ]]; then					# if max_redir is not a whole number...
						echo "Error: max_redir must be a positive, whole number. Default value (10) will be used." >&2
						max_redir=10
					elif [ $time_max -eq "0" ]; then						# if it's zero...
						echo "Error: max_redir must be greater than zero. Default value (10) will be used." >&2
						max_redir=10
					fi
					;;
				v)
					verbose="--verbose"
	esac
done

shift "$((OPTIND-1))"														# Discard the options and sentinel --

#############################################################################################################################
#	BEGIN SCRIPT
#############################################################################################################################
# The main part of the script is the curl command.
# Some options are always present:
# 	silent for efficiency and not clogging the console
# 	insecure to allow insecure connections
# 	location to follow redirects
#	include to store the headers
# 	write-out to add [http_code] at the end of the output file
#	connect-timeout
#	max-time
#	header for no cache
#	max-redirs for limiting the number of redirections followed
# 
# Two options are present depending on:
#	proxy?		->	then the proxy option is active
#	device?		->	then the user-agent option is active
#
# If there is need for debugging, add the verbose option
#############################################################################################################################

extra_output="\n\nHTTP-Code: %{http_code}\n"								# Argument for --write-out option of curl
																			# Writes the HTTP code only
																			
no_cache="Cache-Control: no-cache"											# Argument for the --header option of curl
																			# Check the URL without cache
url_no_cache=$( shuf -i 100-9999 -n 1 )										# Generate a random string to attach to the URL
																			# and generate better no-cache checks

echo "URL: $1" > $2															# Writes the URL to output file
domain=?$( echo $1 | cut -d/ -f3 )											# Extract the domain from the URL
echo "IP: $( dig +short $domain | sort -g | tail -n1 )" >> $2				# Print the domain IP to output file
echo "User-Agent: $device" >> $2											# Print the flag for user-agent to output file

proxy_test=$( dig +short $domain | sort -g | tail -n1 )
if [[ -n proxy_test ]]; then												# If IP found, check the URL
##########################################
#	CHECKING WITH PROXY
##########################################
	if $oxylab_flag || $proxy_flag || $custom_flag; then						# If the url is to be checked with a proxy...
		echo "Checking $1$url_no_cache with proxy from $country..."				# Reminder that a proxy is going to be used
		echo "Proxy: $country" >> $2											# Flag for proxy-checked attached to output file
		echo "" >> $2															# New line for better visualization
		
	#	country=$( bash country_code.sh "$country" )							# Get the country ALPHA-2 code

	#	Decide which proxy is going to be used (Oxylabs, from Database or Custom)
	#	and create the proxy string accordingly.
	#		- Needs testing: Custom proxy
	#
	#	Note:
	#		- curl will try to connect to a proxy for ~130 seconds before failing the connection.
	#		- Setting time_connect lower than 131 will fail the connection to the proxy earlier.
	#		- With the proxies tested (oxylabs and other 3 proxies) 5 seconds was more than enough to stablish the connection.
	#		- More testing is needed to fix a decent default value for time_connect.
	#		- Oxylab is quite unstable, losing the connecting while trying to connect when too many redirections are followed.

		if $oxylab_flag; then													# If the proxy is from oxylabs...
			proxy="http://customer-analyst-cc-$country:CTAC%40cyxtera.com2018@pr.oxylabs.io:7777"
		elif $proxy_flag; then													# If the proxy is from database...
			proxy_list=$( grep "$country@" 'proxies.txt' )						# Fetch ALL proxies from the specified country
			num_proxies=$( echo $proxy_list | wc -w )							# How many proxies were found?
			if [[ "$num_proxies" -eq 0 ]]; then									# If no proxy was found...
				echo "No proxy found for $country while checking \"$1\"" 		# Display error
				exit 3															# Exit script with code 3 (exit number is random)
			elif [[ "$num_proxies" -gt 1 ]]; then								# If more than one proxy was found...
				proxy_list=$( shuf -e -n 1 $proxy_list )						# 	select one proxy randomly
			fi
																				# Extract the parts of the proxy...
			proxy_protocol=$( echo "$proxy_list" | cut -d@ -f2)					#	- Protocol
			if [[ -n $proxy_protocol ]]; then									#		Some string styling...
				proxy_protocol=$proxy_protocol://								#		If not null, add "://" at the end
			fi
			proxy_ip=$( echo "$proxy_list" | cut -d@ -f3)						#	- IP
			proxy_port=$( echo "$proxy_list" | cut -d@ -f4)						#	- Port
			if [[ -n $proxy_port ]]; then										#		More string styling...
				proxy_port=:$proxy_port											#		If not null, add ":" at the start
			fi
			
			proxy="$proxy_protocol$proxy_ip$proxy_port"							# Create the proxy string
																				# If no protocol, curl defaults to http
																				# If no port, curl defaults to 1080
			
		elif $custom_flag; then													# If it is a custom proxy...
			proxy_protocol=0
			while [[ ! $proxy_protocol =~ ^[1-3]$ ]]; do
				echo "Please specify the protocol to be used:"					# Ask for the protocol for the proxy
				echo "1) Http"													# Ask for it until a valid option is entered
				echo "2) Socks4"
				echo "3) Socks5"
				read proxy_protocol
			done
			case $proxy_protocol in												# Depending on the option, assign the value to
						1)														# the variable
							proxy_protocol="http"
							;;
						2)
							proxy_protocol="socks4"
							;;
						3)
							proxy_protocol="socks5"
							;;
			esac
			proxy_ip=0
			while ! valid_ip $proxy_ip; do										# Ask for the IP of the proxy
				echo "Please specify the proxy IP:"								# Ask for it until a valid IP is entered
				read proxy_ip
			done
			proxy_port=a
			while [[ ! $proxy_port =~ ^[0-9]{1,5}$ ]] && [[ ! $proxy_port -le 65535 ]]; do
				echo "Please specify the proxy port:"							# Ask for a port for the proxy
				read proxy_port													# Ask for it until a valid port is entered
			done
			
			proxy="$proxy_protocol://$proxy_ip:$proxy_port"						# Create the proxy string
			
		fi

	#	Now time to check the URL

		if $mobile_flag; then													# AND from a mobile device...
			curl --fail --silent --insecure --location --include --write-out "$extra_output" \
			--connect-timeout $time_connect --max-time $time_max --header "$no_cache" \
			--max-redirs $max_redir --proxy "$proxy" --user-agent "$user_agent" $verbose $1$url_no_cache >> $2
			temp="$?"
			echo "Exit-Code: $temp" >> $2
			exit_description $temp "$2"
			
		else																	# NOT from a mobile device...
			curl --fail --silent --insecure --location --include --write-out "$extra_output" \
			--connect-timeout $time_connect --max-time $time_max --header "$no_cache" \
			--max-redirs $max_redir --proxy "$proxy" $verbose $1$url_no_cache >> $2
			temp="$?"
			echo "Exit-Code: $temp" >> $2
			exit_description $temp "$2"
		fi
	##########################################
	#	CHECKING WITHOUT PROXY
	##########################################
	else
	#	echo "Checking \"$1\" without proxy..."									# Reminder that a proxy is not going to be used
		echo "Proxy: NO" >> $2													# Flag for proxy-checked attached to output file
		echo "" >> $2															# New line for better visualization
		
		if $mobile_flag; then													# AND from a mobile device...
			curl --fail --silent --insecure --location --include --write-out "$extra_output" \
			--connect-timeout $time_connect --max-time $time_max --header "$no_cache" \
			--max-redirs $max_redir --user-agent "$user_agent" $verbose $1$url_no_cache >> $2
			temp="$?"
			echo "Exit-Code: $temp" >> $2
			exit_description $temp "$2"
		else																	# NOT from a mobile device...
			curl --fail --silent --insecure --location --include --write-out "$extra_output" \
			--connect-timeout $time_connect --max-time $time_max --header "$no_cache" \
			--max-redirs $max_redir $verbose $1$url_no_cache >> $2
			temp="$?"
			echo "Exit-Code: $temp" >> $2
			exit_description $temp "$2"
		fi
	fi
else
	echo "Proxy: NULL" >> $2
	echo "" >> $2
	echo "" >> $2
	echo "" >> $2
	echo "HTTP-Code: 000" >> $2
	echo "Exit-Code: 0" >> $2
	echo "No IP found" >> $2
fi
title=$( cat "$2" | grep '<title>' | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/ip' )
echo "Title: $title" >> $2													# Extract and print the Website Title
time=$(date +"%Y-%m-%d %T")													# Fetch time of review
echo "Date: $time" >> $2													# Print date of review to output file
