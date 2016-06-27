#!/bin/bash
#
# for AWS EC2 boot init shell
#
# chkconfig:   - 83 15
#
# /etc/php.ini
#   upload_tmp_dir = /media/ephemeral0/tmp/
#
# /etc/php.d/apc.ini
#   apc.mmap_file_mask=/media/ephemeral0/tmp/apc.XXXXXX
#
# /etc/nginx/nginx.conf
#   client_body_temp_path /media/ephemeral0/nginx/client_body;
#   proxy_temp_path       /media/ephemeral0/nginx/proxy;
#   fastcgi_temp_path     /media/ephemeral0/nginx/fastcgi;
#   uwsgi_temp_path       /media/ephemeral0/nginx/uwsgi;
#   scgi_temp_path        /media/ephemeral0/nginx/scgi;
#
# /etc/php-fpm.d/www.conf
#   env[TMP] = /media/ephemeral0/tmp/
#   env[TMPDIR] = /media/ephemeral0/tmp/
#   env[TEMP] = /media/ephemeral0/tmp/

#TMP_DIR=/media/ephemeral0/tmp
#NGINX_DIR=/media/ephemeral0/nginx
ZABBIX_AGENTD_CONF=/etc/zabbix/zabbix_agentd.conf

case "$1" in
	start)
		if [ ! -z ${TMP_DIR} -a ! -d ${TMP_DIR} ]; then
			mkdir -p ${TMP_DIR}
			chmod ugo+rwx ${TMP_DIR}
		fi


		if [ ! -z ${NGINX_DIR} -a ! -d ${NGINX_DIR} ]; then
			mkdir -p ${NGINX_DIR}
			chown nginx:nginx ${NGINX_DIR}
		fi

		if [ ! -z ${ZABBIX_AGENTD_CONF} -a -f ${ZABBIX_AGENTD_CONF} ]; then
			SETTING_NEW="Hostname=`echo ${HOSTNAME%%.*}`"
			SETTING_OLD=`grep -e "^Hostname=" ${ZABBIX_AGENTD_CONF}`
			if [ "${SETTING_NEW}" != "${SETTING_OLD}" ]; then
				sed -i "s/^Hostname=.*/${SETTING_NEW}/g" ${ZABBIX_AGENTD_CONF}
			fi
		fi

		;;
	*)
		echo $"Usage: $0 {start}"
		exit 2
esac
