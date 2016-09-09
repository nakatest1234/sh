#!/bin/sh

FTP_DIR='/mnt/ebs1/ftp_data'
VSFTPD_USER_DIR='/etc/vsftpd/vsftpd_user_out'
VSFTPD_USER_FILE='/etc/vsftpd/user_list_out.txt'
VSFTPD_USER='virtualftpuser'

if [ $# -eq 0 ]; then
	echo "${0} <ID1,PW1> [ID2,PW2] [ID3,PW3] ..."
	exit
fi

for line in "${@}"; do
	ARR=(`echo ${line} | tr -s ',' ' '`)
	ftp_user=${ARR[0]}
	ftp_pw=${ARR[1]}

	cp -p ${VSFTPD_USER_FILE} ${VSFTPD_USER_FILE}.`date +%Y%m%d%H%I%S`
	echo -e "${ftp_user}\n${ftp_pw}" >> ${VSFTPD_USER_FILE}

	chown -R ${VSFTPD_USER}. ${FTP_DIR}/${ftp_user}
	chmod -R go-rwx ${FTP_DIR}/${ftp_user}

	echo "local_root=${FTP_DIR}/${ftp_user}" > ${VSFTPD_USER_DIR}/${ftp_user}
	chmod -R go-rwx ${VSFTPD_USER_DIR}/${ftp_user}
done

echo "============================================================="
echo "sudo db_load -T -t hash -f user_list_out.txt user_list_out.db"
echo "============================================================="
