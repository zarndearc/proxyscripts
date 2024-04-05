#!/bin/bash
echo -e "\033[1;36mUninstalling Squid Proxy... \033[0m"

systemctl stop squid > /dev/null 2>&1

systemctl disable squid > /dev/null 2>&1

apt remove --purge squid -y > /dev/null 2>&1

rm -rf /etc/squid > /dev/null 2>&1


rm -f /usr/local/bin/squid-uninstall /usr/local/bin/squid-add-user > /dev/null 2>&1

echo "\n\n\nSquid Proxy uninstalled successfully.\n\n" 

echo -e "\033[1;36mThank you for using Netbay Proxy installer.\033[0m"
echo "\nCheck out Netbay Hosting Solution for premium services and purchase Netbay Proxies for high-speed browsing."
