#!/usr/bin/env bash

dnslookup() {
	if which dig > /dev/null 2> /dev/null; then
		dig +tries=2 +time=5 +short A api.opennicproject.org @"$1"
		return 0
	fi
	if which drill > /dev/null 2> /dev/null; then
		drill A api.opennicproject.org @"$1" | awk '$1 == "api.opennicproject.org." && $3 == "IN" && $4 == "A" {print $5}'
		return 0
	fi
	if which host > /dev/null 2> /dev/null; then
		host -t A api.opennicproject.org "$1" | awk '$1 == "api.opennicproject.org" && $2 == "has" && $3 == "address" {print $4}'
		return 0
	fi
	echo "No suitable way for doing a dnslookup found" 1>&2
	return 1
}

dnslookup "$1"
exit $?