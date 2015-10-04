#!/usr/bin/env bash

_ping() {
	if which fping > /dev/null 2> /dev/null; then
		fping -q -p 20 -r 0 -c 25 "$@" 2>&1
		return 0
	fi
	if which ping > /dev/null 2> /dev/null; then
		echo "Falling back to ping/grep/awk method which is VERY unreliable. You should really consider installing fping!" 1>&2
		for host in "$@"; do
			echo "$host"
		done | ./_multiexec.sh ./_ping_single.sh 100
		return 0
	fi
	echo "No suitable way for measuring latency found" 1>&2
	return 1
}

_ping "$@"
exit $?