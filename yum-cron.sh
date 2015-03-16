#!/bin/sh

OPT_CHECK='-d 1'
OPT_UPDATE='-d 1 -C -R 10 -y --exclude=kernel*,openssh*,gcc*,kde*,php*,mysql*,zabbix*'
HOSTNAME=`hostname`
DATE=`date +%Y-%m-%d_%H:%M:%S`
SENDMAIL='/usr/sbin/sendmail'

if [ `id -u` != `id -u root` ]; then
	echo STDERR "root"
	exit 1
fi

### from env
EMAIL=`echo $MAILTO`

if [ -z ${EMAIL} ]; then
	EMAIL='root'
fi

set -u

TMP=`mktemp`

cat <<_EOT_ >> ${TMP}
From: root@${HOSTNAME}
To: ${EMAIL}
Subject: yum ${DATE} ${HOSTNAME}

yum chech-update ${OPT_CHECK}
_EOT_

yum check-update ${OPT_CHECK} >> ${TMP}

cat <<_EOT_ >> ${TMP}

yum update ${OPT_UPDATE}
_EOT_

yum update ${OPT_UPDATE} >> ${TMP}

cat ${TMP} | ${SENDMAIL} -t

rm ${TMP}
