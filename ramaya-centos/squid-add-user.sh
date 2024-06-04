#!/bin/bash

read -p "Enter username: " username
read -s -p "Enter password: " password
echo
read -s -p "Confirm password: " password_confirm
echo


if [ "$password" != "$password_confirm" ]; then
    echo -e "\nPasswords do not match. Exiting."
    exit 1
fi

echo -e "\nSelect a port number:"
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


server_ip=$(hostname -I | cut -d' ' -f1)

htpasswd -b /etc/squid/passwd "$username" "$password"
echo -e "\nUser $username added to Squid Proxy on port $port\n"


sed -i "s/http_port [0-9]\+/http_port $port/" /etc/squid/squid.conf


systemctl restart squid > /dev/null 2>&1



echo -e "\n\n\nproxyData: $server_ip:$port:$username:$password\n\n"

echo -e "\033[1;36mThank you for using Ramaya Proxy installer.\033[0m"

