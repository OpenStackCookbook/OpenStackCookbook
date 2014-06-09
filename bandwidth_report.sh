#!/bin/bash

# Pre-Requisites
# Add new pipeline element to allow a Gauge for Neutron, instead of Cumulative
# See http://cjchand.wordpress.com/2014/01/16/transforming-cumulative-ceilometer-stats-to-gauges/
#
# Install 'bc' (apt-get install bc)

DATE_START=$(date --date="0 month -$(($(date +%-d)-1)) days" "+%FT%T")
FRIENDLY_DATE_START=$(date -u --date="0 month -$(($(date +%-d)-1)) days")
DATE_NOW=$(date "+%FT%T")
FRIENDLY_DATE_NOW=$(date -u)
TMP_FILE=/tmp/bytes.txt


# Networks
NETWORKS="192"

# Prep

echo "Start: ${FRIENDLY_DATE_START}"
echo "End  : ${FRIENDLY_DATE_NOW}"

for N in ${NETWORKS}; do

	rm -f $TMP_FILE

	# Cycle through the networks, get info to display
	NETWORK_INFO=$(neutron net-list | grep ${N} | awk '{print $4,"("$2")"}')

	neutron port-list | egrep "$N" | awk '{print $2}' | while read P; do 
		p=$(echo ${P:0:11})
		echo $p | while read T; do 
			ceilometer meter-list | egrep "outgoing.bytes.*$T" | awk '{print $8}' | while read I; do 
				ceilometer sample-list --meter network.outgoing.bytes -q "resource_id=$I;timestamp>${DATE_START};timestamp<=${DATE_NOW}" | awk '/gauge/ {print $8}' | while read BYTES; do 
					echo $BYTES >> /tmp/bytes.txt; 
				done;
			done
		done
	done

	if [[ ! -f /tmp/bytes.txt ]]
	then
		echo "No data collected for ${NETWORK_INFO}"
		exit -1
	fi

	BYTES=$(sed /tmp/bytes.txt -e ':a;N;$!ba;s/\n/+/g' | bc)

	echo "${NETWORK_INFO} Bytes: ${BYTES}"
done
