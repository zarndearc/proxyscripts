#!/bin/bash

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Root check
if [ "$(whoami)" != "root" ]; then
    echo -e "${RED}ERROR: Run as root or use sudo.${NC}"
    exit 1
fi

# Remove old Squid
if command -v squid >/dev/null 2>&1 || [ -x /usr/sbin/squid ]; then
    echo -e "${YELLOW}Squid is already installed. Removing...${NC}"
    systemctl stop squid
    systemctl disable squid
    yum remove -y squid
    rm -rf /etc/squid
    echo -e "${GREEN}Removed old Squid.${NC}"
fi

# Default port
port=3128

# Random generator
generate_random_word() {
    tr -dc 'a-z' </dev/urandom | head -c8
}

initial_user=$(generate_random_word)
initial_pass=$(generate_random_word)

# Install dependencies
yum install -y squid httpd-tools python3 python3-pip firewalld
pip3 install flask

# Ensure firewall is running
systemctl enable firewalld
systemctl start firewalld

# Prepare config
mkdir -p /etc/squid
touch /etc/squid/passwd
mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
touch /etc/squid/blacklist.acl

generate_squid_conf() {
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
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Ramaya Proxy Service
auth_param basic credentialsttl 2 hours
acl password proxy_auth REQUIRED
http_access allow localhost
http_access allow password
http_access deny all
forwarded_for off
EOF
}

generate_squid_conf

# Set credentials
htpasswd -b /etc/squid/passwd "$initial_user" "$initial_pass"

# Start Squid
systemctl enable squid
systemctl restart squid

# Open port in firewall
firewall-cmd --permanent --add-port=$port/tcp >/dev/null
firewall-cmd --reload >/dev/null

# Set up Flask API
API_SECRET="Black@98345611"

cat << 'EOF' > /usr/local/bin/api_proxy.py
#!/usr/bin/env python3
from flask import Flask, request, jsonify, abort
import subprocess, random, string, socket, os, threading

app = Flask(__name__)
API_SECRET = "Black@98345611"
passwd_file = "/etc/squid/passwd"
conf_file = "/etc/squid/squid.conf"

def get_server_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        ip = s.getsockname()[0]
    except:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def get_series(ip):
    return ".".join(ip.split(".")[0:2])

def get_current_port():
    with open(conf_file, 'r') as f:
        for line in f:
            if line.startswith("http_port"):
                return line.strip().split()[1]
    return "3128"

def generate_random_word():
    return ''.join(random.choice(string.ascii_lowercase) for _ in range(8))

def restart_squid():
    subprocess.run(["systemctl", "restart", "squid"])

def update_passwd_and_restart(user, password):
    os.remove(passwd_file)
    subprocess.run(["htpasswd", "-cb", passwd_file, user, password])
    threading.Thread(target=restart_squid).start()

@app.route('/api/proxy', methods=['POST'])
def get_proxy():
    if request.headers.get('Authorization') != API_SECRET:
        abort(401)
    new_user = generate_random_word()
    new_pass = generate_random_word()
    update_passwd_and_restart(new_user, new_pass)
    ip = get_server_ip()
    return jsonify({
        "ipseries": get_series(ip),
        "ip": ip,
        "port": get_current_port(),
        "user": new_user,
        "pass": new_pass
    })

@app.route('/api/change-port', methods=['POST'])
def change_port():
    if request.headers.get('Authorization') != API_SECRET:
        abort(401)
    data = request.get_json()
    if not data or 'port' not in data:
        return jsonify({"error": "Missing 'port'"}), 400
    new_port = str(data['port'])
    with open(conf_file, 'r') as f:
        lines = f.readlines()
    with open(conf_file, 'w') as f:
        for line in lines:
            if line.startswith("http_port"):
                f.write(f"http_port {new_port}\n")
            else:
                f.write(line)
    subprocess.run(["firewall-cmd", "--permanent", "--add-port=" + new_port + "/tcp"])
    subprocess.run(["firewall-cmd", "--reload"])
    threading.Thread(target=restart_squid).start()
    return jsonify({"message": f"Port changed to {new_port}"}), 200

@app.route('/api/rebuild', methods=['POST'])
def rebuild_proxy():
    if request.headers.get('Authorization') != API_SECRET:
        abort(401)
    with open(conf_file, 'r') as f:
        lines = f.readlines()
    with open(conf_file, 'w') as f:
        for line in lines:
            if line.startswith("http_port"):
                f.write("http_port 3128\n")
            else:
                f.write(line)
    subprocess.run(["firewall-cmd", "--permanent", "--add-port=3128/tcp"])
    subprocess.run(["firewall-cmd", "--reload"])
    user = generate_random_word()
    password = generate_random_word()
    update_passwd_and_restart(user, password)
    ip = get_server_ip()
    return jsonify({
        "message": "Proxy reset and credentials regenerated.",
        "ipseries": get_series(ip),
        "ip": ip,
        "port": "3128",
        "user": user,
        "pass": password
    })

@app.route('/api/status', methods=['GET'])
def check_status():
    return jsonify({"status": "active"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=16969)
EOF

chmod +x /usr/local/bin/api_proxy.py

# Create systemd service
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

systemctl daemon-reload
systemctl enable api_proxy.service
systemctl start api_proxy.service

# Notify n8n webhook
server_ip=$(hostname -I | awk '{print $1}')
series=$(echo "$server_ip" | cut -d'.' -f1,2)
webhook_url="https://n8n.technoconnect.io/webhook-test/proxy-create"
auth="Black@98345611"

curl -X POST "$webhook_url" \
     -H "Authorization: $auth" \
     -H "Content-Type: application/json" \
     -d '{
        "ipseries": "'"$series"'",
        "ip": "'"$server_ip"'",
        "port": "'"$port"'",
        "user": "'"$initial_user"'",
        "pass": "'"$initial_pass"'"
     }' >/dev/null 2>&1 &

echo -e "${GREEN}Squid installed with API endpoints:${NC}"
echo -e "${CYAN}Proxy: ${server_ip}:${port}:${initial_user}:${initial_pass}${NC}"
echo -e "${CYAN}API: http://${server_ip}:16969/api/proxy${NC}"
echo -e "${CYAN}Change Port: http://${server_ip}:16969/api/change-port${NC}"
echo -e "${CYAN}Rebuild: http://${server_ip}:16969/api/rebuild${NC}"
echo -e "${CYAN}Status: http://${server_ip}:16969/api/status${NC}"
