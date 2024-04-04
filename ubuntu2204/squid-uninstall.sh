#!/bin/bash

# Stop Squid service
systemctl stop squid
# Disable Squid service
systemctl disable squid
# Remove Squid package
apt remove --purge squid -y
# Remove Squid configuration directory
rm -rf /etc/squid > /dev/null 2>&1

# Remove squid-uninstall.sh and squid-add-user.sh scripts
rm -f /usr/local/bin/squid-uninstall /usr/local/bin/squid-add-user > /dev/null 2>&1

echo "Squid Proxy uninstalled successfully." 

# Marketing content
echo -e "\033[1;36mThank you for using Netbay Proxy installer.\033[0m"
echo "Check out Netbay Hosting Solution for premium services and purchase Netbay Proxies for high-speed browsing."
