#!/bin/sh

OPT_CHECK='-d 1'
OPT_UPDATE='-d 1 -R 10 -y --exclude=kernel*,openssh*,gcc*,kde*,php*,mysql*,zabbix*'
HOSTNAME=`hostname`
DATE=`date '+%Y-%m-%d %H:%M:%S'`
SENDMAIL='/usr/sbin/sendmail'

if [ `id -u` != `id -u root` ]; then
	echo STDERR "root"
	exit 1
fi

### arg1: echo flg
FLG=0
if [ $# -gt 0 ]; then
	FLG=$1
fi

### from env
EMAIL=`echo $MAILTO`

set -u

TMP=`mktemp`

cat <<_EOT_ >> ${TMP}
# ---------------------------------------------------------
# yum check-update ${OPT_CHECK}
# ---------------------------------------------------------
_EOT_

yum check-update ${OPT_CHECK} >> ${TMP}

cat <<_EOT_ >> ${TMP}
# ---------------------------------------------------------
# yum update ${OPT_UPDATE}
# ---------------------------------------------------------
_EOT_

yum update ${OPT_UPDATE} >> ${TMP}

if [ "${FLG}" = 0 ]; then
	if [ ! -z "${EMAIL}" ]; then
		BODY=`mktemp`
		cat <<_EOT_ >> ${BODY}
From: root@${HOSTNAME}
To: ${EMAIL}
Subject: yum ${DATE} ${HOSTNAME}

_EOT_
		cat ${TMP} >> ${BODY}

		cat ${BODY} | ${SENDMAIL} -t

		rm ${BODY}
	fi
else
	cat ${TMP}
fi

rm ${TMP}
