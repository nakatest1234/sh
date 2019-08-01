#!/bin/sh

set -eu

DOMAIN=example.com
ROUTE53_HOSTZONE=Z1************
ALB_HOSTZONE=Z2************
DNSNAME=dualstack.example-00000000.ap-northeast-1.elb.amazonaws.com.

ACTION=${1:-}
NAME=${2:-}

if [ -z "${ACTION}" -o -z "${NAME}" ]; then
	echo "${0} <action> <name>" >&2
	echo "  action: CREATE, DELETE" >&2
	echo "  name  : <here>.${DOMAIN}" >&2
	echo "" >&2
	exit 1
fi

NAME=`echo ${NAME} | sed -e 's/\..*//g'`
SERVER_NAME=${NAME}.${DOMAIN}

aws route53 change-resource-record-sets --hosted-zone-id /hostedzone/${ROUTE53_HOSTZONE} --cli-input-json '{"ChangeBatch":{"Changes":[{"Action":"'${ACTION}'","ResourceRecordSet":{"Name":"'${SERVER_NAME}'","Type":"A","AliasTarget":{"HostedZoneId":"'${ALB_HOSTZONE}'","DNSName":"'${DNSNAME}'","EvaluateTargetHealth":false}}}]}}'
