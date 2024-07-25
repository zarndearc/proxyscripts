#!/bin/bash

############################################################
# Fast Proxy Installer
# Author: Zarn De Arc
# Github: https://github.dev/zarndearc/proxyscripts/ramaya
############################################################

if [ `whoami` != root ]; then
	echo "ERROR: You need to run the script as user root or add sudo before command."
	exit 1
fi

if [ ! -f /usr/bin/htpasswd ]; then
    echo "htpasswd not found"
    exit 1
fi

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
	echo -e "${GREEN}Thank you for using Ramaya Proxy Service.${NC}"
    SQUID_USER=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1)
	SQUID_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

	htpasswd -b -c /etc/squid/passwd $SQUID_USER $SQUID_PW > /dev/null 2>&1

	server_ip=$(hostname -I | cut -d' ' -f1)
	echo -e "${CYAN}Username : ${SQUID_USER}${NC}"
	echo -e "${CYAN}Password : ${SQUID_PW}${NC}"
 	echo -e "${CYAN}Port : 3128${NC}"
	echo -e "${CYAN}Proxy : ${server_ip}:3128:${SQUID_USER}:${SQUID_PW}${NC}"
	
	systemctl restart squid > /dev/null 2>&1
	systemctl restart squid3 > /dev/null 2>&1
    exit 1
fi


