#!/bin/bash

# Define variables
SERVICE_NAME="NetbayControllerClient"
PORT=11500
SECRET_KEY=$(openssl rand -base64 32)
HOSTNAME=$(hostname -I | awk '{print $1}')

# Update and install necessary packages
if [ -x "$(command -v apt)" ]; then
    sudo apt update && sudo apt install -y python3 python3-pip
elif [ -x "$(command -v yum)" ]; then
    sudo yum install -y epel-release
    sudo yum install -y python3 python3-pip
fi

# Install Flask and psutil
pip3 install Flask psutil

# Create the Flask application
cat <<EOF > /opt/$SERVICE_NAME/app.py
from flask import Flask, request, jsonify
import psutil
import platform
import os
import subprocess

app = Flask(__name__)
SECRET_KEY = "$SECRET_KEY"

def authenticate(req):
    auth = req.headers.get("Authorization")
    return auth == SECRET_KEY

@app.route('/fetch_specs', methods=['GET'])
def fetch_specs():
    if not authenticate(request):
        return jsonify({"error": "Unauthorized"}), 401
    
    specs = {
        "os": platform.system(),
        "cpu_cores": psutil.cpu_count(logical=False),
        "storage_size": psutil.disk_usage('/').total // (2**30),  # in GB
        "ram": psutil.virtual_memory().total // (2**30)  # in GB
    }
    return jsonify(specs)

@app.route('/fetch_usage', methods=['GET'])
def fetch_usage():
    if not authenticate(request):
        return jsonify({"error": "Unauthorized"}), 401

    usage = {
        "cpu_usage": psutil.cpu_percent(interval=1),
        "ram_usage": psutil.virtual_memory().percent,
        "network": psutil.net_io_counters()._asdict(),
        "disk_io": psutil.disk_io_counters()._asdict()
    }
    return jsonify(usage)

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

# Create the systemd service file
cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=$SERVICE_NAME

[Service]
ExecStart=/usr/bin/python3 /opt/$SERVICE_NAME/app.py
WorkingDirectory=/opt/$SERVICE_NAME
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Print the URL and secret key
echo "Service URL: http://$HOSTNAME:$PORT"
echo "Secret Key: $SECRET_KEY"

