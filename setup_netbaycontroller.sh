#!/bin/bash

# Define variables
SERVICE_NAME="NetbayControllerClient"
PORT=11500
SECRET_KEY=$(openssl rand -base64 32)
HOSTNAME=$(hostname -I | awk '{print $1}')
WORK_DIR="/opt/$SERVICE_NAME"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
FIREWALLD_SERVICE_FILE="/usr/lib/firewalld/services/$SERVICE_NAME.xml"
UFW_RULE_FILE="/etc/ufw/applications.d/$SERVICE_NAME"

# Function to create the Flask application
create_flask_app() {
  cat <<EOF | sudo tee $WORK_DIR/app.py > /dev/null
from flask import Flask, request, jsonify
import psutil
import distro
import subprocess
import math

app = Flask(__name__)
SECRET_KEY = "$SECRET_KEY"

def authenticate(req):
    auth = req.headers.get("Authorization")
    return auth == SECRET_KEY

def convert_size(size_bytes):
    if size_bytes == 0:
        return "0B"
    size_name = ("B", "KB", "MB", "GB", "TB")
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}"

def get_linux_distribution():
    try:
        dist = distro.linux_distribution(full_distribution_name=False)
        os_name = dist[0]
        os_version = dist[1]
        return (os_name, os_version)
    except:
        return ("Unknown", "Unknown")

@app.route('/fetch_specs', methods=['GET'])
def fetch_specs():
    if not authenticate(request):
        return jsonify({"error": "Unauthorized"}), 401
    
    os_name, os_version = get_linux_distribution()
    
    specs = {
        "os": f"{os_name} {os_version}",
        "cpu_cores": psutil.cpu_count(logical=False),
        "storage_size": round(psutil.disk_usage('/').total / (2**30)),  # in GB
        "ram": round(psutil.virtual_memory().total / (2**30))  # in GB
    }
    return jsonify(specs)

@app.route('/fetch_usage', methods=['GET'])
def fetch_usage():
    if not authenticate(request):
        return jsonify({"error": "Unauthorized"}), 401

    try:
        cpu_percentage = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        net_io = psutil.net_io_counters()
        disk_io = psutil.disk_io_counters()

        usage = {
            "cpu_percentage": cpu_percentage,
            "ram_percentage": ram.percent,
            "used_ram": convert_size(ram.used),
            "network_in": convert_size(net_io.bytes_recv),
            "network_out": convert_size(net_io.bytes_sent),
            "disk_read": convert_size(disk_io.read_bytes),
            "disk_write": convert_size(disk_io.write_bytes)
        }
        return jsonify(usage)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/change_password', methods=['POST'])
def change_password():
    if not authenticate(request):
        return jsonify({"error": "Unauthorized"}), 401
    
    data = request.json
    username = data.get("username")
    password = data.get("password")
    
    if not username or not password:
        return jsonify({"error": "Username and password required"}), 400

    try:
        subprocess.run(['sudo', 'passwd', username], input=f"{password}\n{password}\n", text=True, check=True)
        return jsonify({"message": "Password changed successfully"})
    except subprocess.CalledProcessError as e:
        return jsonify({"error": str(e)}), 500

@app.route('/reboot', methods=['POST'])
def reboot():
    if not authenticate(request):
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        subprocess.run(['sudo', 'reboot'], check=True)
        return jsonify({"message": "Server is rebooting"})
    except subprocess.CalledProcessError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$PORT)
EOF
}

# Check if the service file exists
if [ -f "$SERVICE_FILE" ]; then
  echo "Service already exists. Updating secret key and restarting the service..."
  create_flask_app
  sudo systemctl restart $SERVICE_NAME
else
  echo "Setting up the service for the first time..."

  # Update and install necessary packages
  if [ -x "$(command -v dnf)" ]; then
      sudo dnf install -y python3 python3-pip firewalld
      sudo systemctl enable --now firewalld
  elif [ -x "$(command -v yum)" ]; then
      sudo yum install -y epel-release
      sudo yum install -y python3 python3-pip firewalld
      sudo systemctl enable --now firewalld
  elif [ -x "$(command -v apt)" ]; then
      sudo apt update && sudo apt install -y python3 python3-pip ufw
      sudo ufw --force enable
  fi

  # Install Flask, psutil, and distro library
  pip3 install Flask psutil distro

  # Create working directory with correct permissions
  sudo mkdir -p $WORK_DIR
  sudo chown -R $USER:$USER $WORK_DIR
  sudo chmod 755 $WORK_DIR

  # Create the Flask application
  create_flask_app

  # Create the systemd service file with logging
  cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=$SERVICE_NAME

[Service]
ExecStart=/usr/bin/python3 $WORK_DIR/app.py
WorkingDirectory=$WORK_DIR
Restart=always
User=$USER
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

  # Create the firewalld service definition file (for RHEL)
  if [ -n "$FIREWALLD_SERVICE_FILE" ]; then
    cat <<EOF | sudo tee $FIREWALLD_SERVICE_FILE > /dev/null
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>$SERVICE_NAME</short>
  <description>$SERVICE_NAME Service</description>
  <port protocol="tcp" port="$PORT"/>
</service>
EOF

    # Reload firewalld and add the service to the public zone
    sudo firewall-cmd --reload
    sudo firewall-cmd --zone=public --add-service=$SERVICE_NAME --permanent
  fi

  # Create the ufw application definition file (for Debian/Ubuntu)
  if [ -n "$UFW_RULE_FILE" ]; then
    cat <<EOF | sudo tee $UFW_RULE_FILE > /dev/null
[$SERVICE_NAME]
title=$SERVICE_NAME
description=$SERVICE_NAME Service
ports=$PORT/tcp
EOF

    # Reload ufw and allow the service
    sudo ufw reload
    sudo ufw allow $PORT/tcp
  fi

  # Reload systemd, enable and start the service
  sudo systemctl daemon-reload
  sudo systemctl enable $SERVICE_NAME
  sudo systemctl start $SERVICE_NAME
fi

# Print the URL and secret key
echo "Service URL: http://$HOSTNAME:$PORT"
echo "Secret Key: $SECRET_KEY"
