#!/usr/bin/env bash

_single_ping() {
	result=$(ping -q -i 0.5 -c 10 "$1")
	host=$(echo "$result" | fgrep ' ping statistics ---' | awk '{print $2}')
	xmtrcvloss=$(echo "$result" | fgrep '% packet loss' | awk '{print $1"/"$4"/"$6}')
	minavgmax=$(echo "$result" | fgrep -e 'rtt ' -e 'round-trip ' | awk '{print $4}' | awk -F'/' '{print $1"/"$2"/"$3}')
	echo "$host : xmt/rcv/%loss = $xmtrcvloss, min/avg/max = $minavgmax"
}

_single_ping "$1"
exit $?