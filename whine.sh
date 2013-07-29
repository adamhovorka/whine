#!/bin/bash

#####===-- whine v1.0
#
#  Copyright (c) 2013 Adam Hovorka
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#
#####===--
#
#  Configuration
#
# The email that you want to send Google Voice
# SMS messages from and its password
EMAIL=you@gmail.com
PASSWORD=password
#
# The number of the phone you want to text 
NUMBER=1234567890
#
#
#  -=Messages
#
# Success message
MESSAGESENT="Whine sent successfully."
#
# Cooldown for the command in seconds (default 300)
COOLDOWN=300
#
# Message for an impatient user
WITHINCOOLDOWN="The @whine command has a five minute cooldown."
#
#
#  -=Miscellaneous
#
# The directory to use for the cooldown lock files
# NOTE: YOU MUST CREATE THIS DIRECTORY MANUALLY!
LOCKDIR="~/.whine"
#
# Full path to server.log
SERVERLOG="~/minecraft/server.log"
#
# The name of the screen session your server is running in
SERVER=minecraft
#
# The name of the screen session you want whine to run in
SESSNAME=whine
#
# Uncomment this if you want the daemon to log to a file
#MAKELOG="-L"
#
#####===--


# If there are no arguments, start the daemon
if [ $# -eq 0 ]; then
	if ! [ "$(screen -ls | grep $SESSNAME)" ]; then 
		screen $MAKELOG -S $SESSNAME $0 daemon
	fi
fi

case "$1" in
	"daemon" )
		# Parse the server log for @whine commands
		tail -n 1 -f "$SERVERLOG" |
		sed -une "/INFO] </s/^[^<]*<\([^>]*\)>/\1:/p" |
		sed -une "/: @whine/s/ @whine//p;" |
		while read whine; do
			TIMESTAMP=$(date "+%y:%m:%d::%H:%M:%S")
			echo "$TIMESTAMP $whine"
			$0 timeout "$whine" &
		done
		;;

	"say" )
		# Echo a message to the server
		screen -S $SERVER -X stuff "say $2
"
		;;

	"timeout" )
		# Check if the user is within their cooldown period
		USER=$(echo "$2" | sed "s/:.*//g")
		cd $LOCKDIR
		if [ -e "$USER" ]; then
			$0 say "$WITHINCOOLDOWN"
		else
			touch "$USER"
			$0 send "$2"
			$0 say "$MESSAGESENT"
			sleep $TIMEOUT
			rm "$USER"
		fi
		;;

	"send" )
		# Die if no message was supplied
		if ! [ "$2" ]; then
			echo "You must supply a message."
			exit 1
		fi

		# If a new number was supplied, use it
		if [ $# -eq 3 ]; then NUMBER=$3; fi

		# Retrieve the authorization code
		AUTH=$(curl https://www.google.com/accounts/ClientLogin -s \
		--data-urlencode Email=$EMAIL --data-urlencode Passwd=$PASSWORD \
		-d accountType=GOOGLE -d service=grandcentral | grep "Auth" | tail -c +6)

		# Retrieve the other authorization codes
		SEND=$(curl -s --header "Authorization: GoogleLogin auth=$AUTH" \
		"https://www.google.com/voice/m/sms")
		_RNR_SE=$(echo "$SEND" | grep "_rnr_se" | cut -d '"' -f 6)
		_ID=$(echo "$SEND" | grep 'name="id"' | cut -d '"' -f 6)
		_C=$(echo "$SEND" | grep 'name="c"' | cut -d '"' -f 6)

		# Send the SMS message
		curl -s --header "Authorization: GoogleLogin auth=$AUTH" \
		-d "number=$NUMBER&_rnr_se=$_RNR_SE&id=$_ID&c=$_C&smstext=$1" \
		"https://www.google.com/voice/m/sendsms" > /dev/null
		;;

esac
