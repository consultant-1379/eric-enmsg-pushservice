#!/bin/bash

# ********************************************************************
#
# (c) Ericsson LMI 2020 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson LMI. The programs may be used and/or copied only with
# the written permission from Ericsson LMI or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************

# GLOBAL VARIABLES
readonly CURL="/usr/bin/curl"
readonly JBOSS_HTTP_PORT="8080"

POD_HTTP_URL="http://127.0.0.1:$JBOSS_HTTP_PORT"

RESPONSE=$($CURL -I -m 10 --write-out "http_code:%{http_code},time_total:%{time_total},time_connect:%{time_connect}" --connect-timeout 7 --silent --output /dev/null "$POD_HTTP_URL")
CURL_EXIT=$?
if [[ $CURL_EXIT -ne 0 ]]; then
	logger "CN_JBOSS_HEALTHCHECK command failed: url: \"$POD_HTTP_URL\" returned \"$RESPONSE\" curl_exit code : \"$CURL_EXIT\""
else
	TIME_TOTAL=$(echo $RESPONSE | awk -v FS="(,)" '{print $2}' | awk -v FS="(:)" '{print $2}')
	# Only log when a succesfull curl command takes longer than 10ms, this is to avoid flooding the log
	if [[ $TIME_TOTAL > 0.010 ]]; then
		logger "CN_JBOSS_HEALTHCHECK command succeeded: url: \"$POD_HTTP_URL\" returned \"$RESPONSE\" curl_exit code : \"$CURL_EXIT\""
	fi
fi

exit $CURL_EXIT