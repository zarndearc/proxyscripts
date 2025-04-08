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

# Check if Squid is already installed, reset configuration if it is
if command -v squid >/dev/null 2>&1 || [ -x /usr/sbin/squid ]; then
    echo -e "${YELLOW}\nSquid Proxy is already installed. Resetting configuration...\n${NC}"
    systemctl stop squid > /dev/null 2>&1
    
    # Backup existing configuration and create a new one
    if [ -f /etc/squid/squid.conf ]; then
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak.$(date +%Y%m%d%H%M%S)
    fi
    
    # Clear all previous passwords by removing and recreating passwd file
    mkdir -p /etc/squid
    rm -f /etc/squid/passwd
    touch /etc/squid/passwd
    chmod 644 /etc/squid/passwd
    
    # Create blacklist file if it doesn't exist
    touch /etc/squid/blacklist.acl
    
    # Restart squid after configuration changes
    systemctl restart squid > /dev/null 2>&1
else
    # Install Squid if not already installed
    echo -e "${YELLOW}Installing Squid Proxy...${NC}"
    yum update -y > /dev/null 2>&1
    yum install -y squid httpd-tools > /dev/null 2>&1
    mkdir -p /etc/squid
    touch /etc/squid/passwd
    chmod 644 /etc/squid/passwd
    touch /etc/squid/blacklist.acl
fi

# Create Squid configuration
cat <<EOF > /etc/squid/squid.conf
http_port 3128
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
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Secure Proxy Service
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
echo -e "${GREEN}\nSquid Proxy configured successfully.\n${NC}"

# Generate an 8-digit random username
USERNAME_DIGITS=$(shuf -i 10000000-99999999 -n 1)
SQUID_USER="user${USERNAME_DIGITS}"

# Generate an 8-digit random password
PASSWORD_DIGITS=$(shuf -i 10000000-99999999 -n 1)
SQUID_PW="pass${PASSWORD_DIGITS}"

# Add user to htpasswd file
htpasswd -b /etc/squid/passwd "$SQUID_USER" "$SQUID_PW"

# Restart Squid service to apply new user credentials
systemctl restart squid > /dev/null 2>&1

# Check if firewall-cmd exists and allow port if it does
if command -v firewall-cmd >/dev/null 2>&1; then
    echo -e "${YELLOW}Configuring firewall...${NC}"
    firewall-cmd --permanent --add-port=3128/tcp > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
else
    echo -e "${YELLOW}firewall-cmd not found. Skipping firewall configuration.${NC}"
    echo -e "${YELLOW}Make sure port 3128 is allowed in your firewall if you have one.${NC}"
fi

# Get server IP address
server_ip=$(hostname -I | cut -d' ' -f1)

# Display the details to the user
echo -e "${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}   Proxy Server Created Successfully      ${NC}"
echo -e "${GREEN}===========================================${NC}"
echo
echo -e "${CYAN}Username : ${SQUID_USER}${NC}"
echo -e "${CYAN}Password : ${SQUID_PW}${NC}"
echo -e "${CYAN}Port     : 3128${NC}"
echo -e "${CYAN}IP       : ${server_ip}${NC}"
echo -e "${CYAN}Proxy    : ${server_ip}:3128:${SQUID_USER}:${SQUID_PW}${NC}"
echo -e "${NC}"

# Create a user management script
cat <<'EOF' > /usr/local/bin/create-proxy-user
#!/bin/bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Check if run as root
if [ "$(whoami)" != "root" ]; then
    echo -e "${RED}ERROR: You need to run this script as root or with sudo.${NC}"
    exit 1
fi

# Generate an 8-digit random username
USERNAME_DIGITS=$(shuf -i 10000000-99999999 -n 1)
SQUID_USER="user${USERNAME_DIGITS}"

# Generate an 8-digit random password
PASSWORD_DIGITS=$(shuf -i 10000000-99999999 -n 1)
SQUID_PW="pass${PASSWORD_DIGITS}"

# Add user to htpasswd file
htpasswd -b /etc/squid/passwd "$SQUID_USER" "$SQUID_PW"

# Restart Squid service to apply new user credentials
systemctl restart squid > /dev/null 2>&1

# Get server IP address
server_ip=$(hostname -I | cut -d' ' -f1)

# Display the details
echo -e "${GREEN}New proxy user created:${NC}"
echo -e "${CYAN}Username : ${SQUID_USER}${NC}"
echo -e "${CYAN}Password : ${SQUID_PW}${NC}"
echo -e "${CYAN}Port     : 3128${NC}"
echo -e "${CYAN}IP       : ${server_ip}${NC}"
echo -e "${CYAN}Proxy    : ${server_ip}:3128:${SQUID_USER}:${SQUID_PW}${NC}"
EOF

chmod 755 /usr/local/bin/create-proxy-user

# Create an uninstall script
cat <<'EOF' > /usr/local/bin/squid-uninstall
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if run as root
if [ "$(whoami)" != "root" ]; then
    echo -e "${RED}ERROR: You need to run this script as root or with sudo.${NC}"
    exit 1
fi

# Stop and disable Squid
systemctl stop squid > /dev/null 2>&1
systemctl disable squid > /dev/null 2>&1

# Remove Squid package
yum remove -y squid > /dev/null 2>&1

# Remove configuration files
rm -rf /etc/squid > /dev/null 2>&1

# Remove added scripts
rm -f /usr/local/bin/create-proxy-user
rm -f /usr/local/bin/squid-uninstall

# Check if firewall-cmd exists and remove port if it does
if command -v firewall-cmd >/dev/null 2>&1; then
    echo -e "${YELLOW}Removing firewall rule...${NC}"
    firewall-cmd --permanent --remove-port=3128/tcp > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
fi

echo -e "${GREEN}Squid Proxy has been completely uninstalled from your system.${NC}"
EOF

chmod 755 /usr/local/bin/squid-uninstall

echo -e "${YELLOW}\nTo create additional proxy users, simply run: ${GREEN}sudo create-proxy-user${NC}"
echo -e "${YELLOW}To uninstall Squid completely, run: ${GREEN}sudo squid-uninstall${NC}\n"