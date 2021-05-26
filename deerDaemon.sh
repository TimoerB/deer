#!/bin/bash
# Deer daemon

cd "$HOME/.deer"
deerId=""
deerIdPath="$HOME/.deer/deerId.conf"
hostname=$(hostname)

while [[ true ]]
do
	if [ -f "$deerIdPath" ]; then
		read -r deerId < "$deerIdPath"
		repos=""
		deer ps | sed 's/ /_/g' > repos.tmp
		while IFS= read -r repo
		do
			repos="$repos$repo,"
		done < repos.tmp
		rm -f repos.tmp
		curl -L "https://deercore.org/api.php?action=searchRepo&hostname=$hostname&deerId=$deerId&repos=$repos" | \
			python3 -c "import sys, json; print(json.load(sys.stdin)['name'])"
	else
		echo "No deer id set. Doing nothing, just sleeping.."
	fi

	sleep 5m
done
