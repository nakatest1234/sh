#!/bin/sh

# 実行インスタンスにSG(SecurityGroup)の変更権限が必要
# SGに80番ポートを追加
# letencryptをstandaloneで実行
# SGの80番ポートを削除
# postfix, dovecotの設定reload
# slackに通知

function post_slack() {
	local URL=$1
	local CHANNEL=$2
	local MESSAGE=$3
	local BOTNAME=${4:-$0}
	local FACEICON=${5:-:raising_hand:}

	if [ "x${URL}" != "x" -a "x${CHANNEL}" != "x" -a "x${MESSAGE}" != "x" ]; then
		curl -s -S -X POST --data-urlencode "payload={ \
			\"channel\": \"${CHANNEL}\", \
			\"username\": \"${BOTNAME}\", \
			\"icon_emoji\": \"${FACEICON}\", \
			\"text\": \"${MESSAGE}\" \
			}" ${URL} > /dev/null

	fi
}

WEBHOOKURL="https://hooks.slack.com/services/XXXXXXXX/YYYYYYYYY/ZZZZZZZZZZZZZZZZZZZZZZZZ"

### SG add rule
aws ec2 authorize-security-group-ingress --group-id sg-XXXXXXXX --protocol tcp --port 80 --cidr 0.0.0.0/0

### Update SSL
sudo /root/letsencrypt/letsencrypt-auto certonly --text --renew-by-default --standalone --standalone-supported-challenges http-01 -d mail.example.com -m postmaster@example.com --agree-tos #--dry-run

### SG remove rule
aws ec2 revoke-security-group-ingress --group-id sg-XXXXXXXX --protocol tcp --port 80 --cidr 0.0.0.0/0

service postfix reload
service dovecot reload

if [ $? = 0 ]; then
	post_slack $WEBHOOKURL "#general" "update mail.example.com certfile."
fi
