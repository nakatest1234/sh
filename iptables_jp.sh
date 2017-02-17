#!/bin/sh

### /etc/sysconfig/iptables-config
### IPTABLES_MODULES="ip_conntrack_ftp ip_nat_ftp"

CMD_IPTABLES_SAVE='/sbin/iptables-save'
CMD_IPTABLES_CONF='/etc/sysconfig/iptables';
CMD_IPTABLES_START='/bin/systemctl start iptables'
CMD_IPTABLES_STOP='/bin/systemctl stop iptables'

ALLOW_IPS=(
10.0.0.0/16
)

ALLOW_IPS_FTP=(
)

COUNTRY_LIST=(
https://ipv4.fetus.jp/jp.txt
)

### ACCEPT IP FILES
TMP_FILE=`mktemp tmp.XXXXXXXXXX`

for file in ${COUNTRY_LIST[@]}; do
	wget -q ${file} -O - >> ${TMP_FILE}
	sleep 0.5
done

sed -i -n -e "/^[0-9]/p" ${TMP_FILE}

### STOP
eval ${CMD_IPTABLES_STOP}

### DEFAULT
iptables -P INPUT   DROP
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD DROP

### CHAIN
iptables -N ACCEPT_COUNTRY

while read line; do
	iptables -A ACCEPT_COUNTRY -s ${line} -j ACCEPT
done < ${TMP_FILE}

rm -f ${TMP_FILE}

### BASE
iptables -A INPUT -i lo -j ACCEPT

### ALLOW
for ip_address in ${ALLOW_IPS[@]}; do
	iptables -A INPUT -s ${ip_address} -j ACCEPT
done

### ALLOW FTP
for ip_address in ${ALLOW_IPS_FTP[@]}; do
	iptables -A INPUT -s ${ip_address} -p tcp -m state --state NEW -m multiport --dports ftp,40022:40030 -j ACCEPT
done

iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport ssh        -j ACCEPT_COUNTRY
#iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8081:8084 -j ACCEPT_COUNTRY

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

### OPT
#iptables -A OUTPUT -p tcp -m multiport --dports memcache,mysql ! -d 10.0.1.110/32 -j DROP

### REJECT
iptables -A INPUT   -j REJECT --reject-with icmp-host-prohibited
iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited

### DROP
iptables -A INPUT   -j DROP
iptables -A FORWARD -j DROP

${CMD_IPTABLES_SAVE} > ${CMD_IPTABLES_CONF}
eval ${CMD_IPTABLES_START}
