#!/bin/bash

# Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try using sudo."
   exit 1
fi

echo "Removing old repository files..."
rm -rf /etc/yum.repos.d/*
rm -rf /var/cache/dnf
rm -rf /var/cache/yum
dnf clean all
yum clean all

echo "Creating new repository files..."

# BaseOS Repo
cat > /etc/yum.repos.d/CentOS-Stream-BaseOS.repo <<EOL
[baseos]
name=CentOS Stream 9 - BaseOS
baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOL

echo "BaseOS repository file created."

# AppStream Repo
cat > /etc/yum.repos.d/CentOS-Stream-AppStream.repo <<EOL
[appstream]
name=CentOS Stream 9 - AppStream
baseurl=https://mirror.stream.centos.org/9-stream/AppStream/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOL

echo "AppStream repository file created."

# Clean and update package cache
echo "Cleaning and updating package manager cache..."
dnf clean all
yum clean all
yum makecache --refresh
yum update -y

echo "Repository fix completed successfully!"
