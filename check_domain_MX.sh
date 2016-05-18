#!/bin/sh

# need dig

if [ $# -eq 0 ]; then
	echo "${0} <file>"
else
	if [ -r $1 ]; then
		while read DOMAIN;do
			RET=`dig ${DOMAIN} MX +short`

			if [ -z "${RET}" ]; then
				echo ${DOMAIN}
			fi
		done < $1
	else
		echo "ERROR: ${1}" >&2
	fi
fi
