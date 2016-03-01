#!/bin/sh

HOST="https://ipv4.fetus.jp/"
POSTFIX_CMD="/usr/sbin/postfix"
POSTFIX_DIR="/etc/postfix/blacklist/"

LIST=(
ae.postfix.txt
cn.postfix.txt
in.postfix.txt
kr.postfix.txt
mg.postfix.txt
th.postfix.txt
tw.postfix.txt
vn.postfix.txt
)

TMP_DIR=`mktemp -d tmp.XXXXXXXXXX`

for file in ${LIST[@]}; do
	wget -q ${HOST}${file} -O ${TMP_DIR}/${file}
	if [ "$?" != 0 ]; then
		rm -Rf ${TMP_DIR}
		echo "wget error." >&2
		exit 1
	fi
	sleep 1
done

for file in ${LIST[@]}; do
	cp -fp ${TMP_DIR}/${file} ${POSTFIX_DIR}/${file}
done

rm -Rf ${TMP_DIR}

${POSTFIX_CMD} check

if [ "$?" != 0 ]; then
	echo "postfix check error." >&2
	exit 1
fi

service postfix reload > /dev/null
