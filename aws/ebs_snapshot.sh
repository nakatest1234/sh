#!/bin/sh

### default tag
TAG="AUTOBKUP"

### [memo]
### if --dry-run then "{cmd} || :"

set -u

### const
GET_LIST_TAGS='aws ec2 describe-tags'
GET_INFO_VOLUME='aws ec2 describe-volumes'
CREATE_TAG='aws ec2 create-tags'
GET_LIST_SNAPSHOT='aws ec2 describe-snapshots'
CREATE_SNAPSHOT='aws ec2 create-snapshot'
DELETE_SNAPSHOT='aws ec2 delete-snapshot'
GET_LIST_AMI='aws ec2 describe-images'

DATE=`date +%Y%m%d-%H%M%S`

### get this abs path
PWD=`pwd`; cd `dirname $0`; CMD=`pwd`/`basename $0`; cd ${PWD}

### [args1] tag-name
if [ ${#} -gt 0 ]; then
	TAG=${1}
fi

### get owner_id
OWNER_ID=`aws iam get-user --output text --query='User.UserId'`

### get EBS volumes
VOLUMES=`${GET_LIST_TAGS} --output=text --filters Name=resource-type,Values=volume Name=key,Values=${TAG} --query="Tags[*][ResourceId,Value]" | sed -e "s/\t/,/g"`

if [ $? != 0 ]; then
	logger -t ${CMD} "[ERROR] ${GET_LIST_TAGS}"
	exit 1
fi

if [ ! -n "${VOLUMES}" ]; then
	logger -t ${CMD} "[INFO] No Volumes. tag=${TAG}"
	exit 0
fi

for VOL in ${VOLUMES}; do
	VOL_ID=`echo ${VOL} | awk -F ',' '{print $1}'`
	VOL_GEN=`echo ${VOL} | awk -F ',' '{print $2}'`

	if [ ${VOL_GEN} = 0 ]; then
		logger -t ${CMD} "[INFO] skip TAG value = 0 (volume-id=${VOL_ID})"
		continue
	fi

	CHK_VOL=`${GET_INFO_VOLUME} --output text --filters Name=volume-id,Values=${VOL_ID} --query="Volumes[*][VolumeId]"`

	### check voluem
	if [ "${VOL_ID}" != "${CHK_VOL}" ]; then
		logger -t ${CMD} "[INFO] skip retire volume volume-id=${VOL_ID}"
		continue
	fi

	### create snapshot and get snap-id
	CREATE_SNAP_ID=`${CREATE_SNAPSHOT} --output=text --volume-id=${VOL_ID} --description="${TAG}_${DATE}" --query="SnapshotId"`

	if [ $? != 0 ]; then
		logger -t ${CMD} "[ERROR] ${CREATE_SNAPSHOT}"
		continue
	fi

	logger -t ${CMD} "[INFO] create snapshot volume-id=${VOL_ID} => snap-id=${CREATE_SNAP_ID}"

	### get volume name
	VOL_NAME=`${GET_LIST_TAGS} --output=text --filters Name=resource-id,Values=${VOL_ID} Name=key,Values=Name --query="Tags[*][Value]"`

	### escape
	VOL_NAME=`echo ${VOL_NAME} | sed -e "s/\"/'\'\"/g"`

	### set tag[Name]
	${CREATE_TAG} --resources=${CREATE_SNAP_ID} --tags="Key=Name,Value=\"${VOL_NAME}\""

	### get snapshots
	SNAPSHOTS=`${GET_LIST_SNAPSHOT} --output=text --owner-ids ${OWNER_ID} --filters Name=volume-id,Values=${VOL_ID} --query="Snapshots[*][StartTime,SnapshotId]" | sort -r | sed -e "s/\t/,/g"`

	if [ $? != 0 ]; then
		logger -t ${CMD} "[ERROR] ${GET_LIST_SNAPSHOT}"
		continue
	fi

	if [ ! -n "${SNAPSHOTS}" ]; then
		logger -t ${CMD} "[INFO] No Snapshot. volume-id=${VOL_ID}"
		continue
	fi

	i=0
	for SNAP in ${SNAPSHOTS}; do
		SNAP_ID=`echo ${SNAP} | awk -F ',' '{print $2}'`

		### get AMI USED snapshot
		AMIS=`${GET_LIST_AMI} --output=text --owners self --filter="Name=block-device-mapping.snapshot-id,Values=${SNAP}" --query="Images[*][ImageId]"`

		if [ ! -z ${AMIS} ]; then
			### skip AMI's snapshot
			logger -t ${CMD} "[INFO] Used for AMI. snap-id=${SNAP_ID}"
			continue
		fi

		i=`expr ${i} + 1`

		if [ ${i} -gt ${VOL_GEN} ]; then
			### delete snapshot
			${DELETE_SNAPSHOT} --snapshot-id=${SNAP_ID} > /dev/null 2>&1

			if [ $? = 0 ]; then
				logger -t ${CMD} "[INFO] delete snapshot snap-id=${SNAP_ID} (volume-id=${VOL_ID})"
			fi
		fi
	done
done
