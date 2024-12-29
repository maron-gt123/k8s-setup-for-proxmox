# !/bin/bash

# region : set variables


# ------end region------

sudo nmcli connection modify "Wired connection 1" ipv4.method manual ipv4.addresses 192.168.10.132/24,192.168.10.1

# update.sh create
cat > update.sh <<EOF
#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
EOF

chmod 700 update.sh
./update.sh

# authorized_keys create
mkdir -p ~/.ssh && chmod 700 ~/.ssh
curl -sS https://github.com/maron-gt123.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# setting ntp
cat > /etc/systemd/timesyncd.conf <<EOF
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file, or by creating "drop-ins" in
# the timesyncd.conf.d/ subdirectory. The latter is generally recommended.
# Defaults can be restored by simply deleting this file and all drop-ins.
#
# See timesyncd.conf(5) for details.

[Time]
NTP=ntp.jst.mfeed.ad.jp
#FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
#ConnectionRetrySec=30
#SaveIntervalSec=60
EOF
systemctl restart systemd-timesyncd
timedatectl timesync-status

# setting timezone Asia/Tokyo
timedatectl set-timezone Asia/Tokyo
timedatectl
cd

# setting ufw
sudo apt install -y ufw
echo "y" | ufw enable
ufw default deny
ufw allow from 192.168.10.0/24 to any port 22
ufw allow from 192.168.10.0/24 to any port 80
ufw allow from 192.168.10.0/24 to any port 443
ufw allow 53

# install
apt-get install -y pdns-server pdns-backend-mysql git php php-fpm apache2 php-mysql php-intl pdns-recursor
