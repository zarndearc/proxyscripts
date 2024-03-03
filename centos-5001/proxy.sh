#!/bin/bash

# Update system and install required packages
yum update -y
yum install nano firewalld wget -y

# Start firewalld service
systemctl start firewalld

# Download and run Squid Proxy Installer script
wget https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid3-install.sh
bash squid3-install.sh

# Change Squid proxy port to 5001
sed -i 's/3128/5001/g' /etc/squid/squid.conf

# Add firewall rule to allow traffic on port 5001
firewall-cmd --permanent --zone=public --add-port=5001/tcp
firewall-cmd --reload

# Restart Squid service
systemctl restart squid
