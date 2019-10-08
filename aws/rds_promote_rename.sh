#!/bin/sh

# master マスタ
# slave マスタのスレーブ
# slave2 マスタをスケールアップするための追加スレーブ
# 1. slave2を昇格する
# 2. slave2とmaster/slave1が分離
# 3. 全てに-oldというサフィックスつけた名前にリネーム
# 4. slave2-old を master にリネーム(+設定変更)
# 5. 新しいmasterからslave1を作成

TARGET_MASTER=test20191008-master
TARGET_SLAVE1=test20191008-slave
TARGET_SLAVE2=test20191008-slave2

SLEEP=180
START=`date`

echo "${TARGET_SLAVE2} promote"
aws rds promote-read-replica \
  --db-instance-identifier ${TARGET_SLAVE2}

sleep ${SLEEP}

aws rds wait db-instance-available --db-instance-identifier ${TARGET_SLAVE2}

sleep 10

echo "${TARGET_SLAVE1} mod"
aws rds modify-db-instance \
  --db-instance-identifier ${TARGET_SLAVE1} \
  --new-db-instance-identifier ${TARGET_SLAVE1}-old \
  --apply-immediately

echo "${TARGET_SLAVE2} mod"
aws rds modify-db-instance \
  --db-instance-identifier ${TARGET_SLAVE2} \
  --new-db-instance-identifier ${TARGET_SLAVE2}-old \
  --apply-immediately

echo "${TARGET_MASTER} mod"
aws rds modify-db-instance \
  --db-instance-identifier ${TARGET_MASTER} \
  --new-db-instance-identifier ${TARGET_MASTER}-old \
  --apply-immediately

echo "${TARGET_SLAVE1}-old wait"
echo "${TARGET_SLAVE2}-old wait"
echo "${TARGET_MASTER}-old wait"
sleep ${SLEEP}
aws rds wait db-instance-available --db-instance-identifier ${TARGET_SLAVE1}-old
aws rds wait db-instance-available --db-instance-identifier ${TARGET_SLAVE2}-old
aws rds wait db-instance-available --db-instance-identifier ${TARGET_MASTER}-old

sleep 10

echo "${TARGET_SLAVE2}-old mod"
aws rds modify-db-instance \
  --db-instance-identifier ${TARGET_SLAVE2}-old \
  --new-db-instance-identifier ${TARGET_MASTER} \
  --backup-retention-period 7 \
  --preferred-backup-window "18:00-18:30" \
  --auto-minor-version-upgrade \
  --preferred-maintenance-window "tue:18:30-tue:19:00" \
  --apply-immediately

echo "${TARGET_MASTER} wait"
sleep ${SLEEP}
aws rds wait db-instance-available --db-instance-identifier ${TARGET_MASTER}

sleep 10

echo "${TARGET_SLAVE1} make"
aws rds create-db-instance-read-replica \
  --db-instance-identifier ${TARGET_SLAVE1} \
  --source-db-instance-identifier ${TARGET_MASTER}

echo "${TARGET_SLAVE1} wait"
sleep ${SLEEP}
aws rds wait db-instance-available --db-instance-identifier ${TARGET_SLAVE1}

echo ${START}
date
