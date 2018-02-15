#!/bin/sh

### CONFIG
MYNETWORK=192.168.0.0/24
ALLOW_IPS=(
192.168.0.0/16
172.16.0.0/12
10.0.0.0/8
)

DENY_IP_LIST=(
https://ipv4.fetus.jp/kr.txt
https://ipv4.fetus.jp/kp.txt
https://ipv4.fetus.jp/cn.txt
https://ipv4.fetus.jp/in.txt
)

CONFFILE="/etc/sysconfig/iptables"
CMD_RESTART="/sbin/service iptables restart"
#CONFFILE="/etc/sysconfig/iptables"
#CMD_RESTART="/bin/systemctl restart iptables.service"

cp -p ${CONFFILE} `basename ${CONFFILE}`.bk

### INIT
TMPFILE=`mktemp tmp.XXXXXXXXXX`

cat << EOS > ${TMPFILE}
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:DENY_IP_CHAIN - [0:0]
:STEALTH_SCAN  - [0:0]

-A INPUT -j ACCEPT -i lo
-A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED

### flagment
-A INPUT -j DROP -f

### NetBIOS
-A INPUT  -j DROP -s ! ${MYNETWORK} -p tcp -m multiport --dports 135,137,138,139,445
-A INPUT  -j DROP -s ! ${MYNETWORK} -p udp -m multiport --dports 135,137,138,139,445
-A OUTPUT -j DROP -d ! ${MYNETWORK} -p tcp -m multiport --dports 135,137,138,139,445
-A OUTPUT -j DROP -d ! ${MYNETWORK} -p udp -m multiport --dports 135,137,138,139,445

-A INPUT -j DROP -s 127.0.0.0/8
-A INPUT -j DROP -s 169.254.0.0/16
-A INPUT -j DROP -s 192.0.2.0/24
-A INPUT -j DROP -s 224.0.0.0/4
-A INPUT -j DROP -s 240.0.0.0/5

-A INPUT -j DROP -d 0.0.0.0/8
-A INPUT -j DROP -d 255.255.255.255/32

EOS


### ALLOW
if [ ${#ALLOW_IPS[@]} -gt 0 ]; then
	for ip_address in ${ALLOW_IPS[@]}; do
		echo "-A INPUT -j ACCEPT -s ${ip_address}" >> ${TMPFILE}
	done
	echo "" >> ${TMPFILE}
fi

### MAIN
cat << EOS >> ${TMPFILE}

### IP spoofing
-A INPUT -j DROP -s 10.0.0.0/8
-A INPUT -j DROP -s 172.16.0.0/12
-A INPUT -j DROP -s 192.168.0.0/16

### DROP IP
-A INPUT -j DENY_IP_CHAIN

### Stealth Scan
-A STEALTH_SCAN -j LOG  --log-prefix "stealth_scan_attack: " --log-level=info
-A STEALTH_SCAN -j DROP

-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW 
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags ALL NONE
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags SYN,FIN SYN,FIN
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags SYN,RST SYN,RST
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags FIN,RST FIN,RST
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags ACK,FIN FIN
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags ACK,PSH PSH
-A INPUT -j STEALTH_SCAN -p tcp --tcp-flags ACK,URG URG

### original
#-A INPUT -j ACCEPT_COUNTRY -p tcp -m state --state NEW -m tcp --dport ssh
#-A INPUT -j ACCEPT_COUNTRY -p tcp -m state --state NEW -m tcp --dport 8081:8084
#-A INPUT -j ACCEPT         -p tcp -m state --state NEW -m tcp -m multiport --dports http,https
#-A OUTPUT -j DROP -p tcp -m multiport --dports memcache,mysql ! -d 10.0.1.110/32

### last
-A INPUT   -j REJECT --reject-with icmp-host-prohibited
-A INPUT   -j DROP

-A FORWARD -j ACCEPT -m physdev --physdev-is-bridged
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j DROP

EOS


### DENY IP FILES
if [ ${#DENY_IP_LIST[@]} -gt 0 ]; then
	echo "### DENY IP" >> ${TMPFILE}

	DENY_IP_FILE=`mktemp tmp.XXXXXXXXXX`
	
	for file in ${DENY_IP_LIST[@]}; do
		wget -q ${file} -O - >> ${DENY_IP_FILE}
		sleep 1
	done
	
	sed -i -n -e "/^[0-9]/p" ${DENY_IP_FILE}
	sed -i    -e 's/^\(.\+\)$/-A DENY_IP_CHAIN -j DROP -s \1/' ${DENY_IP_FILE}
	cat ${DENY_IP_FILE} >> ${TMPFILE}
	echo "" >> ${TMPFILE}

	rm -f ${DENY_IP_FILE}
fi

### COMMIT
echo "COMMIT" >> ${TMPFILE}

mv ${TMPFILE} ${CONFFILE}

#cat ${TMPFILE}
#rm -f ${TMPFILE}

${CMD_RESTART}
