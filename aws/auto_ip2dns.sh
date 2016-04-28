#!/bin/sh

### Show Policy
### {
###     "Version": "2012-10-17",
###     "Statement": [
###         {
###             "Action": [
###                 "route53:ChangeResourceRecordSets"
###             ],
###             "Effect": "Allow",
###             "Resource": [
###                 "arn:aws:route53:::hostedzone/Z32I5QZAJJE8AM"
###             ]
###         }
###     ]
### }

ZONEID=$1
PUBLIC_HOST=$2

TMPL='{
  "HostedZoneId": "{%ZONEID%}",
  "ChangeBatch": {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
        "Name": "{%HOST%}",
        "ResourceRecords": [
          {
            "Value": "{%IP%}"
          }
        ],
        "TTL": 300,
        "Type": "A"
        }
      }
    ]
  }
}'

InstanceID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
IP=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-ipv4`

JSON=`echo ${TMPL} | sed -e "s/{%ZONEID%}/${ZONEID}/g;s/{%IP%}/${IP}/g;s/{%HOST%}/${PUBLIC_HOST}/g;"`

aws route53 change-resource-record-sets --cli-input-json "${JSON}"
