#!/bin/sh

set -eu

OLD_IFS=${IFS}
EXEC_DIR=$(dirname $(readlink -f $0))
GITDIR=${1:-$EXEC_DIR}
NUM=${2:-3}
GIT="/usr/local/bin/git --no-pager -C ${GITDIR}"

atexit() {
	cd ${EXEC_DIR}
}
trap atexit EXIT
trap 'trap - EXIT; atexit; exit -1' SIGHUP SIGINT SIGTERM ERR

BRANCH_NAMES=`${GIT} branch -r --merged origin/master | grep -v origin/master`

for BRANCH_NAME in ${BRANCH_NAMES}
do
	LOG=`${GIT} log -n ${NUM} --no-merges --oneline --pretty=format:"[%ar] %an %s" ${BRANCH_NAME}`
	echo $BRANCH_NAME

	IFS=$'\n'
	for j in ${LOG}
	do
		echo "    ${j}"
	done
	IFS=${OLD_IFS}
done

