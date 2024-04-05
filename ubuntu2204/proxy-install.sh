#!/bin/bash

# Custom start text
echo -e "\033[1;36m

@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@%%%%*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@%%       #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@%*.=     .=-%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@%% %%%.   +% -%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@%  %%%%   +%  %%%%%%  %%* %    +    +   %%%%: %# +%%  %%%
@@@#  %%.%%  +%  :%%%%%  =%* %  ::*:  :* .. %%%  *%: #+ +%%%
@@%-  %% .%%=#%   %%%%%   #+ #  %%%%  %% -* %%+   %%   .%%%%
@@@-. %%== %%#% % %%%%%    + #    %%  %%   :%%  # %%#  %%%%%
@@@=%@%%===+%%%%%-%%%%%  % . #  #%%%  %% -#  #  . .%%  %%%%%
@@@@@@%@====+%%%%%%%%%%  %+  #  ##%%  %% -#  . ... %%  %%%%%
@@@@@@%%#*+++@%%%%%%%%% .%%  %    %%  %%    # =%%% -%  %%%%%
@@@@@@%%%:::+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@#--:--:::-+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@%-::::::%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@%%%%*#@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@%%%%%%@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Website: https:netbay.in

\033[0m"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi


# Check if Squid Proxy is already installed
# Check if Squid Proxy is already installed
if command -v squid >/dev/null 2>&1 || [ -x /usr/sbin/squid ]; then
    
    echo '\nSquid Proxy is already installed. Removing existing installation...\n'

    # Stop the Squid service
    systemctl stop squid > /dev/null 2>&1

    # Disable Squid service to prevent it from starting on boot
    systemctl disable squid > /dev/null 2>&1

    # Remove Squid package
    apt remove --purge squid -y > /dev/null 2>&1

    # Remove Squid configuration directory
    rm -rf /etc/squid > /dev/null 2>&1

    echo "\nSquid Proxy uninstalled successfully.\n"
fi





# Installation
if [ ! -x "$(command -v squid)" ]; then
    echo "Installing Squid Proxy..."
    apt update > /dev/null 2>&1
    apt install -y apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    touch /etc/squid/blacklist.acl

# Download squid-add-user script
/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/squid-add-user https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ubuntu2204/squid-add-user.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/squid-add-user

# Download squid-uninstall script
/usr/bin/wget -q --no-check-certificate -O /usr/local/bin/squid-uninstall https://raw.githubusercontent.com/zarndearc/proxyscripts/main/ubuntu2204/squid-uninstall.sh > /dev/null 2>&1
chmod 755 /usr/local/bin/squid-uninstall

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
auth_param basic realm Squid proxy-caching web server
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

    systemctl restart squid > /dev/null 2>&1
    systemctl enable squid > /dev/null 2>&1
    echo "\n\n\nSquid Proxy installed successfully.\n\n"
fi

# Marketing content
echo -e "\033[1;36mThank you for using Netbay Proxy installer.\033[0m"
echo "\nCheck out Netbay Hosting Solution for premium services and purchase Netbay Proxies for high-speed browsing.\n"
echo -e "\033[1;36mYou can add proxy users simply by running 'squid-add-user' and remove Squid completely by running 'squid-uninstall'.\033[0m"
