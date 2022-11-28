#!/bin/bash

if [[ $# -lt 1 ]]
then
	echo "Usage: $0 [-t name] <commit|range>" 1>&2
	exit 1
fi

while true
do
	git test run "$@"
	n=0
	while [[ $n -lt ${GIT_TEST_CONTINOUS_INTERVAL:-30} ]]
	do
		n=$(( n + 1 ))
		echo -n .
		sleep 1
	done
	echo
done
