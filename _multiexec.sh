#!/usr/bin/env bash

_multiexec() {
	whattorun="$1"
	limit="$2"
	if which xargs > /dev/null 2> /dev/null; then
		xargs -n1 -P"$limit" -I% "$whattorun" %
		return 0
	fi
	if which parallel > /dev/null 2> /dev/null; then
		parallel --will-cite -j "$limit" "$whattorun"
		return 0
	fi
	echo "Falling back to spawn/wait/filecache method which is VERY unreliable. You should really consider installing xargs or parallel!" 1>&2
	tmpdir=$(mktemp -d)
	while read line; do
		"$whattorun" "$line" > "$tmpdir/$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM" &
	done
	for pid in $(jobs -p); do
		wait "$pid"
	done
	cat "$tmpdir/"*
	rm -rf "$tmpdir"
	return 0
}

_multiexec "$@"
exit $?