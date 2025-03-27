#!/bin/bash

# Define color codes for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Check if running as root
if [ "$(whoami)" != "root" ]; then
    echo -e "${RED}ERROR: Run the script as root or use sudo.${NC}"
    exit 1
fi

# Remove any existing Squid installation
if command -v squid >/dev/null 2>&1 || [ -x /usr/sbin/squid ]; then
    echo -e "${YELLOW}Squid Proxy is already installed. Removing it...${NC}"
    systemctl stop squid > /dev/null 2>&1
    systemctl disable squid > /dev/null 2>&1
    apt-get purge -y squid > /dev/null 2>&1
    rm -rf /etc/squid > /dev/null 2>&1
    echo -e "${GREEN}Squid Proxy uninstalled successfully.${NC}"
fi

# Fixed proxy port is 3128 (hard-coded in the config)
port=3128

# Function to generate an 8-letter random lowercase string
generate_random_word() {
    tr -dc 'a-z' </dev/urandom | head -c8
}

# Generate initial random credentials
initial_user=$(generate_random_word)
initial_pass=$(generate_random_word)

# Install Squid and required packages
echo -e "${YELLOW}Installing Squid Proxy...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y squid apache2-utils > /dev/null 2>&1

# Create Squid password file and backup existing config if any
touch /etc/squid/passwd
mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
touch /etc/squid/blacklist.acl

# Create Squid configuration file with fixed port 3128
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
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Ramaya Proxy Service
auth_param basic credentialsttl 2 hours
acl password proxy_auth REQUIRED
http_access allow localhost
http_access allow password
http_access deny all
forwarded_for off
EOF

# Start and enable Squid service
systemctl restart squid > /dev/null 2>&1
systemctl enable squid > /dev/null 2>&1

# Add the initial random credentials to Squid's password file
htpasswd -b /etc/squid/passwd "$initial_user" "$initial_pass"

# Open port 3128 in UFW and reload firewall rules
ufw allow 3128/tcp
ufw reload

# ---------------------------
# Set Up API to Regenerate Dynamic Credentials
# ---------------------------
echo -e "${YELLOW}Setting up dynamic proxy API...${NC}"

# Default API secret for Authorization header
API_SECRET="Black@98345611"

# Install Python3, pip, and Flask if not already installed
apt-get install -y python3 python3-pip > /dev/null 2>&1
pip3 install flask > /dev/null 2>&1

# Create the Flask API script that regenerates credentials on POST requests
cat << 'EOF' > /usr/local/bin/api_proxy.py
#!/usr/bin/env python3
from flask import Flask, request, jsonify, abort
import subprocess
import random, string, socket, os, threading

app = Flask(__name__)

# Default API secret for Authorization header
API_SECRET = "Black@98345611"

def get_server_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def generate_random_word():
    return ''.join(random.choice(string.ascii_lowercase) for _ in range(8))

def restart_squid():
    subprocess.run(["systemctl", "restart", "squid"])

@app.route('/api/proxy', methods=['POST'])
def get_proxy():
    # Check only the Authorization header for the API secret
    received_key = request.headers.get('Authorization')
    print("DEBUG: Received key:", received_key)
    if received_key != API_SECRET:
        abort(401)
    new_user = generate_random_word()
    new_pass = generate_random_word()
    passwd_file = "/etc/squid/passwd"
    # Delete the old passwd file and recreate it with new credentials
    os.remove(passwd_file)
    subprocess.run(["htpasswd", "-cb", passwd_file, new_user, new_pass])
    # Restart Squid asynchronously so the API response returns quickly
    threading.Thread(target=restart_squid).start()
    server_ip = get_server_ip()
    return jsonify({
        "proxy": f"{server_ip}:3128",
        "username": new_user,
        "password": new_pass
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Make the API script executable
chmod +x /usr/local/bin/api_proxy.py

# Create a systemd service for the API
cat << 'EOF' > /etc/systemd/system/api_proxy.service
[Unit]
Description=Dynamic Proxy API Service
After=network.target

[Service]
ExecStart=/usr/bin/env python3 /usr/local/bin/api_proxy.py
Restart=always
User=root
Environment=FLASK_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the API service
systemctl daemon-reload
systemctl enable api_proxy.service
systemctl start api_proxy.service

# ---------------------------
# Final Output
# ---------------------------
server_ip=$(hostname -I | cut -d' ' -f1)

echo -e "${NC}"
echo -e "${GREEN}Ramaya Proxy Service installed successfully.${NC}"
echo
echo -e "${CYAN}Initial Squid Credentials:${NC}"
echo -e "${CYAN}Username: ${initial_user}${NC}"
echo -e "${CYAN}Password: ${initial_pass}${NC}"
echo -e "${CYAN}Proxy: ${server_ip}:3128 (Only these credentials are valid until the API generates new ones)${NC}"
echo
echo -e "${GREEN}Dynamic Proxy API is now running on port 5000.${NC}"
echo -e "${CYAN}To request new proxy credentials, send a POST request with the header 'Authorization: Black@98345611' to:${NC}"
echo -e "${CYAN}http://${server_ip}:5000/api/proxy${NC}"
echo -e "\nEach successful API call will delete and recreate the credentials, disabling the previous ones."
