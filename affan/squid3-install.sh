#!/bin/bash
############################################################
# Affan Proxy Installer
# Author: Zarndearc
# Github: https://github.dev/zarndearc/proxyscripts/affan
############################################################
if [ `whoami` != root ]; then
	echo "ERROR: You need to run the script as user root or add sudo before command."
	exit 1
fi

if [ ! -f /usr/bin/wget  ]; then
    yum install -y wget > /dev/null 2>&1
    apt install -y wget > /dev/null 2>&1
fi

/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/sok-find-os https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/sok-find-os.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/sok-find-os

/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/squid-uninstall https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid-uninstall.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/squid-uninstall

/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/fast-add-user https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/fast-add-user.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/fast-add-user

if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
    echo "Proxy service already installed."
    exit 1
fi

if [ ! -f /usr/local/bin/sok-find-os ]; then
    echo "/usr/local/bin/sok-find-os not found"
    exit 1
fi

SOK_OS=$(/usr/local/bin/sok-find-os)

if [ $SOK_OS == "ERROR" ]; then
    echo "OS NOT SUPPORTED."
    echo "Use one of the supported OS (Ubuntu 18.04/20.04/22.04 or CentOS 7/8/9)"
    exit 1;
fi

is_number() {
    local input="$1"
    [[ "$input" =~ ^[0-9]+$ ]]
}

# Prompt the user until they enter a valid number
while true; do
    read -p "Enter custom port number: " SQUID_PORT

    if is_number "$SQUID_PORT"; then
        echo "Valid port number: $SQUID_PORT"
        break
    else
        echo "Invalid input. Please enter a numeric value."
    fi
done

echo "Installing Proxy, please wait."

if [ $SOK_OS == "ubuntu2204" ]; then
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/conf/ubuntu-2204.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    if [ -f /sbin/iptables ]; then
        /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    fi
    service squid restart  > /dev/null 2>&1
    systemctl enable squid > /dev/null 2>&1
elif [ $SOK_OS == "ubuntu2004" ]; then
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    if [ -f /sbin/iptables ]; then
        /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    fi
    service squid restart > /dev/null 2>&1
    systemctl enable squid > /dev/null 2>&1
elif [ $SOK_OS == "ubuntu1804" ]; then
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid3 > /dev/null 2>&1
    touch /etc/squid/passwd
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    service squid restart > /dev/null 2>&1
    systemctl enable squid > /dev/null 2>&1
elif [ $SOK_OS == "ubuntu1604" ]; then
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid3 > /dev/null 2>&1
    touch /etc/squid/passwd
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    service squid restart > /dev/null 2>&1
    update-rc.d squid defaults > /dev/null 2>&1
elif [ $SOK_OS == "ubuntu1404" ]; then
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid3 > /dev/null 2>&1
    touch /etc/squid3/passwd
    /bin/rm -f /etc/squid3/squid.conf
    /usr/bin/touch /etc/squid3/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid3/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    service squid3 restart > /dev/null 2>&1
    ln -s /etc/squid3 /etc/squid > /dev/null 2>&1
    #update-rc.d squid3 defaults
    ln -s /etc/squid3 /etc/squid
elif [ $SOK_OS == "debian8" ]; then
    # OS = Debian 8
    /bin/rm -rf /etc/squid
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid3 > /dev/null 2>&1
    touch /etc/squid3/passwd
    /bin/rm -f /etc/squid3/squid.conf
    /usr/bin/touch /etc/squid3/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid3/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    service squid3 restart
    update-rc.d squid3 defaults
    ln -s /etc/squid3 /etc/squid
elif [ $SOK_OS == "debian9" ]; then
    # OS = Debian 9
    /bin/rm -rf /etc/squid
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    systemctl enable squid
    systemctl restart squid
elif [ $SOK_OS == "debian10" ]; then
    # OS = Debian 10
    /bin/rm -rf /etc/squid
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    systemctl enable squid
    systemctl restart squid
elif [ $SOK_OS == "debian11" ]; then
    # OS = Debian GNU/Linux 11 (bullseye)
    /bin/rm -rf /etc/squid
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/squid.conf
    if [ -f /sbin/iptables ]; then
       /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    fi
    systemctl enable squid
    systemctl restart squid
elif [ $SOK_OS == "debian12" ]; then
    # OS = Debian GNU/Linux 12 (bookworm)
    /bin/rm -rf /etc/squid
    /usr/bin/apt update > /dev/null 2>&1
    /usr/bin/apt -y install apache2-utils squid  > /dev/null 2>&1
    touch /etc/squid/passwd
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/conf.d/serverok.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/conf/debian12.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    if [ -f /sbin/iptables ]; then
        /sbin/iptables -I INPUT -p tcp --dport ${SQUID_PORT} -j ACCEPT > /dev/null 2>&1

    fi
    systemctl enable squid
    systemctl restart squid
elif [ $SOK_OS == "centos7" ]; then
    yum install squid httpd-tools -y
    /bin/rm -f /etc/squid/squid.conf
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/conf/squid-centos7.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1
    if [ -f /usr/bin/firewall-cmd ]; then
    firewall-cmd --zone=public --permanent --add-port=${SQUID_PORT}/tcp > /dev/null 2>&1

    firewall-cmd --reload > /dev/null 2>&1
    fi
elif [ "$SOK_OS" == "centos8" ] || [ "$SOK_OS" == "almalinux8" ] || [ "$SOK_OS" == "almalinux9" ]; then
    yum install squid httpd-tools wget -y
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/conf/squid-centos7.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1
    if [ -f /usr/bin/firewall-cmd ]; then
    firewall-cmd --zone=public --permanent --add-port=${SQUID_PORT}/tcp > /dev/null 2>&1

    firewall-cmd --reload > /dev/null 2>&1
    fi
elif [ "$SOK_OS" == "centos8s" ]; then
    dnf install squid httpd-tools wget -y > /dev/null 2>&1
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/conf/squid-centos7.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    systemctl enable squid  > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1
    if [ -f /usr/bin/firewall-cmd ]; then
    firewall-cmd --zone=public --permanent --add-port=${SQUID_PORT}/tcp > /dev/null 2>&1

    firewall-cmd --reload > /dev/null 2>&1
    fi
elif [ "$SOK_OS" == "centos9" ]; then
    dnf install squid httpd-tools wget -y > /dev/null 2>&1
    mv /etc/squid/squid.conf /etc/squid/squid.conf.sok
    /usr/bin/touch /etc/squid/blacklist.acl
    /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/affan/conf/squid-centos7.conf
    sed -i "s/3128/$SQUID_PORT/g" /etc/squid/squid.conf
    systemctl enable squid  > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1
    if [ -f /usr/bin/firewall-cmd ]; then
    firewall-cmd --zone=public --permanent --add-port=${SQUID_PORT}/tcp > /dev/null 2>&1

    firewall-cmd --reload > /dev/null 2>&1
    fi
fi

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

SQUID_USER=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1)
SQUID_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

htpasswd -b -c /etc/squid/passwd $SQUID_USER $SQUID_PW > /dev/null 2>&1

sed -i 's/Squid proxy-caching web server/AFFAN Proxy Service/g'  /etc/squid/squid.conf

systemctl restart squid > /dev/null 2>&1
systemctl restart squid3 > /dev/null 2>&1


server_ip=$(hostname -I | cut -d' ' -f1)

echo -e "${NC}"
echo -e "${GREEN}Thank you for using Affan Proxy Service.${NC}"
echo
echo -e "${CYAN}Username : ${SQUID_USER}${NC}"
echo -e "${CYAN}Password : ${SQUID_PW}${NC}"
echo -e "${CYAN}Port : ${SQUID_PORT}${NC}"
echo -e "${CYAN}Proxy : ${server_ip}:${SQUID_PORT}:${SQUID_USER}:${SQUID_PW}${NC}"
echo -e "${NC}"
