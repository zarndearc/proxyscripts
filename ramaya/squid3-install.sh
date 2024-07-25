#!/bin/bash
############################################################
# Ramaya Proxy Installer
# Author: Zarn De Arc
# Github: https://github.dev/zarndearc/proxyscripts/ramaya  
############################################################

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to display a loading bar
show_progress() {
    local duration=$1
    local interval=1
    local elapsed=0

    while [ $elapsed -lt $duration ]; do
        echo -ne "["
        for ((i=0; i<$elapsed; i++)); do echo -ne "#"; done
        for ((i=$elapsed; i<$duration; i++)); do echo -ne " "; done
        echo -ne "] $((elapsed * 100 / duration))%\r"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    echo -ne "["
    for ((i=0; i<$duration; i++)); do echo -ne "#"; done
    echo -ne "] 100%\n"
}

# Check for root user
if [ `whoami` != root ]; then
    echo "ERROR: You need to run the script as user root or add sudo before command."
    exit 1
fi

echo "Checking for wget installation..."
show_progress 3
if [ ! -f /usr/bin/wget  ]; then
    echo "Installing wget..."
    show_progress 5
    yum install -y wget > /dev/null 2>&1
    apt install -y wget > /dev/null 2>&1
fi

echo "Downloading necessary scripts..."
show_progress 5
/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/sok-find-os https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/sok-find-os.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/sok-find-os

/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/squid-uninstall https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/squid-uninstall.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/squid-uninstall

/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/squid-add-user https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/ram-add-user.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/squid-add-user

echo "Checking for existing proxy installation..."
show_progress 3
if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
    echo "Proxy service already installed."
    exit 1
fi

if [ ! -f /usr/local/bin/sok-find-os ]; then
    echo "/usr/local/bin/sok-find-os not found"
    exit 1
fi

echo "Determining OS..."
show_progress 3
SOK_OS=$(/usr/local/bin/sok-find-os)

if [ $SOK_OS == "ERROR" ]; then
    echo "OS NOT SUPPORTED."
    echo "Use one of the supported OS (Ubuntu 18.04/20.04/22.04 or CentOS 7/8/9)"
    exit 1;
fi

echo "Installing Proxy, please wait..."
show_progress 5

# Install proxy based on the OS
case $SOK_OS in
    ubuntu2204)
        echo "Installing on Ubuntu 22.04..."
        show_progress 5
        /usr/bin/apt update > /dev/null 2>&1
        show_progress 5
        /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    ubuntu2004)
        echo "Installing on Ubuntu 20.04..."
        show_progress 5
        /usr/bin/apt update > /dev/null 2>&1
        show_progress 5
        /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    ubuntu1804)
        echo "Installing on Ubuntu 18.04..."
        show_progress 5
        /usr/bin/apt update > /dev/null 2>&1
        show_progress 5
        /usr/bin/apt -y install apache2-utils squid3 > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    debian9)
        echo "Installing on Debian 9..."
        show_progress 5
        /usr/bin/apt update > /dev/null 2>&1
        show_progress 5
        /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    debian10)
        echo "Installing on Debian 10..."
        show_progress 5
        /usr/bin/apt update > /dev/null 2>&1
        show_progress 5
        /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    debian11)
        echo "Installing on Debian 11..."
        show_progress 5
        /usr/bin/apt update > /dev/null 2>&1
        show_progress 5
        /usr/bin/apt -y install apache2-utils squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    centos7)
        echo "Installing on CentOS 7..."
        show_progress 5
        yum -y install httpd-tools squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    centos8)
        echo "Installing on CentOS 8..."
        show_progress 5
        dnf -y install httpd-tools squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    centos9)
        echo "Installing on CentOS 9..."
        show_progress 5
        dnf -y install httpd-tools squid > /dev/null 2>&1
        show_progress 5
        echo "Configuring proxy settings..."
        show_progress 5
        touch /etc/squid/passwd
        show_progress 2
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
        show_progress 2
        /usr/bin/touch /etc/squid/blacklist.acl
        show_progress 2
        /usr/bin/wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ramaya/conf/ubuntu-2204.conf
        show_progress 5
        ;;
    *)
        echo "OS NOT SUPPORTED."
        echo "Use one of the supported OS (Ubuntu 18.04/20.04/22.04 or CentOS 7/8/9)"
        exit 1
        ;;
esac

# Common steps for all installations
if [ -f /sbin/iptables ]; then
    /sbin/iptables -I INPUT -p tcp --dport 3128 -j ACCEPT > /dev/null 2>&1
fi
show_progress 2
service squid restart > /dev/null 2>&1
show_progress 2
systemctl enable squid > /dev/null 2>&1
show_progress 2



sed -i 's/Squid proxy-caching web server/Ramaya Proxy Service/g' /etc/squid/squid.conf

echo -e "${NC}"
echo -e "${GREEN}Thank you for using Ramaya Proxy Service.${NC}"
