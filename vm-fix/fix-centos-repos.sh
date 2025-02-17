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

# Extras Repo
cat > /etc/yum.repos.d/CentOS-Stream-Extras.repo <<EOL
[extras]
name=CentOS Stream 9 - Extras
baseurl=https://mirror.stream.centos.org/9-stream/extras/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOL

echo "Extras repository file created."

# High Availability Repo
cat > /etc/yum.repos.d/CentOS-Stream-HA.repo <<EOL
[ha]
name=CentOS Stream 9 - HighAvailability
baseurl=https://mirror.stream.centos.org/9-stream/HighAvailability/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOL

echo "High Availability repository file created."

# PowerTools (CRB) Repo
cat > /etc/yum.repos.d/CentOS-Stream-PowerTools.repo <<EOL
[crb]
name=CentOS Stream 9 - CRB (PowerTools)
baseurl=https://mirror.stream.centos.org/9-stream/CRB/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOL

echo "PowerTools (CRB) repository file created."

# NFV Repo
cat > /etc/yum.repos.d/CentOS-Stream-NFV.repo <<EOL
[nfv]
name=CentOS Stream 9 - NFV
baseurl=https://mirror.stream.centos.org/9-stream/NFV/\$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOL

echo "NFV repository file created."

# Cleaning and updating package manager cache
echo "Cleaning and updating package manager cache..."
dnf clean all
yum clean all
yum makecache --refresh
yum update -y

echo "Repository fix completed successfully!"
