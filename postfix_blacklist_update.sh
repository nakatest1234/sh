#!/bin/sh

HOST="https://ipv4.fetus.jp/"
POSTFIX_CMD="/usr/sbin/postfix"
DENY_FILE="/etc/postfix/deny_ip.txt"
DENY_ORG="/etc/postfix/deny_ip_org.txt"

LIST=(
ae.postfix.txt
cn.postfix.txt
in.postfix.txt
kr.postfix.txt
mg.postfix.txt
th.postfix.txt
tw.postfix.txt
vn.postfix.txt
br.postfix.txt
la.postfix.txt
id.postfix.txt
my.postfix.txt
mx.postfix.txt
bd.postfix.txt
es.postfix.txt
de.postfix.txt
pl.postfix.txt
ar.postfix.txt
cl.postfix.txt
it.postfix.txt
gh.postfix.txt
)

TMP_FILE=`mktemp tmp.XXXXXXXXXX`

cp -fp ${DENY_ORG} ${TMP_FILE}

for file in ${LIST[@]}; do
	wget -q ${HOST}${file} -O - >> ${TMP_FILE}
	sleep 0.5
done

mv -f ${TMP_FILE} ${DENY_FILE}

${POSTFIX_CMD} check

if [ "$?" != 0 ]; then
	echo "postfix check error." >&2
	exit 1
fi

service postfix reload > /dev/null
