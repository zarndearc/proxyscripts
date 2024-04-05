#!/bin/bash

echo -e "\033[1;36mUninstalling Squid Proxy... \033[0m"

# Stop Squid service
systemctl stop squid > /dev/null 2>&1

# Disable Squid service
systemctl disable squid > /dev/null 2>&1

# Remove Squid package
yum remove squid -y > /dev/null 2>&1

# Remove Squid configuration directory
rm -rf /etc/squid > /dev/null 2>&1

# Remove squid-uninstall.sh and squid-add-user.sh scripts
rm -f /usr/local/bin/squid-uninstall /usr/local/bin/squid-add-user > /dev/null 2>&1

echo -e "\n\n\nSquid Proxy uninstalled successfully.\n\n"

# Marketing content
echo -e "\033[1;36mThank you for using Netbay Proxy installer.\033[0m"
echo -e "\nCheck out Netbay Hosting Solution for premium services and purchase Netbay Proxies for high-speed browsing."
