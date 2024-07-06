#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Check if the script is run as root
if [ "$(whoami)" != "root" ]; then
    echo -e "${RED}ERROR: You need to run the script as user root or add sudo before command.${NC}"
    exit 1
fi

# Check if Squid is already installed and remove it
if command -v squid >/dev/null 2>&1 || [ -x /usr/sbin/squid ]; then
    echo -e "${YELLOW}\nSquid Proxy is already installed. Removing existing installation...\n${NC}"
    systemctl stop squid > /dev/null 2>&1
    systemctl disable squid > /dev/null 2>&1
    apt-get purge -y squid 
    rm -rf /etc/squid > /dev/null 2>&1
    echo -e "${GREEN}\nSquid Proxy uninstalled successfully.\n${NC}"
fi

# Select port number
echo -e "${YELLOW}Select a port number from the following options:${NC}"
echo "1) 3128"
echo "2) 5000"
echo "3) 5001"
echo "4) 8000"
echo "5) 8080"
read -p "Enter your choice [1-5]: " port_choice

case $port_choice in
    1) port=3128 ;;
    2) port=5000 ;;
    3) port=5001 ;;
    4) port=8000 ;;
    5) port=8080 ;;
    *) echo -e "${RED}Invalid choice. Exiting.${NC}"; exit 1 ;;
esac

# Take user input for username and password
read -p "Enter username: " SQUID_USER
read -sp "Enter password: " SQUID_PW
echo

# Install Squid if not already installed
if ! command -v squid >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Squid Proxy...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y squid apache2-utils > /dev/null 2>&1
    touch /etc/squid/passwd
    echo -e "${YELLOW}Configuring credentials...${NC}"

    # Backup existing configuration and create blacklist file
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    touch /etc/squid/blacklist.acl


    # Create Squid configuration
    cat <<EOF > /etc/squid/squid.conf
http_port $port
cache deny all
hierarchy_stoplist cgi-bin ?
access_log none
cache_store_log none
cache_log /dev/null
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 1-65535
acl Safe_ports port 1-65535
acl CONNECT method CONNECT
acl siteblacklist dstdomain "/etc/squid/blacklist.acl"
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access deny siteblacklist
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
acl password proxy_auth REQUIRED
http_access allow localhost
http_access allow password
http_access deny all
forwarded_for off
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
EOF

    echo -e "${YELLOW}Starting Squid Proxy...${NC}"
    systemctl restart squid > /dev/null 2>&1
    systemctl enable squid > /dev/null 2>&1
    echo -e "${GREEN}\n\n\nSquid Proxy installed successfully.\n\n${NC}"
fi

# Add user to htpasswd file
htpasswd -b /etc/squid/passwd "$SQUID_USER" "$SQUID_PW" 

# Update Squid configuration
sed -i 's/Squid proxy-caching web server/Proxy Service/g' /etc/squid/squid.conf

# Restart Squid service
systemctl restart squid > /dev/null 2>&1

# Allow traffic on selected port
ufw allow $port/tcp
ufw reload

# Get server IP address
server_ip=$(hostname -I | cut -d' ' -f1)

# Display the details to the user
echo -e "${NC}"
echo -e "${GREEN}Thank you for using Proxy Service.${NC}"
echo
echo -e "${CYAN}Username : ${SQUID_USER}${NC}"
echo -e "${CYAN}Password : ${SQUID_PW}${NC}"
echo -e "${CYAN}Port : ${port}${NC}"
echo -e "${CYAN}Proxy : ${server_ip}:${port}:${SQUID_USER}:${SQUID_PW}${NC}"
echo -e "${NC}"

