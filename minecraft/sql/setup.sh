# !/bin/bash

# region : set variables


# ------end region------



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
#FallbackNTP=ntp.ubuntu.com
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
EOF

systemctl restart systemd-timesyncd
timedatectl timesync-status

# setting timezone Asia/Tokyo
timedatectl set-timezone Asia/Tokyo
timedatectl
cd

echo "y" | ufw enable
ufw default deny
ufw allow from 192.168.1.0/24 to any port 22
ufw allow from 192.168.15.0/24 to any port 22
ufw allow from 192.168.1.0/24 to any port 9100
ufw allow from 192.168.15.0/24 to any port 9100
ufw allow from 192.168.15.0/24 to any port 8086
ufw allow from 192.168.1.0/24 to any port 8086
ufw allow from 192.168.15.0/24 to any port 80


# install prometheus-node-exporter
apt install -y prometheus prometheus-node-exporter

# install mariadb
apt -y install mariadb-server

# install apache
apt -y install apache2

# install php
apt -y install php-fpm

# install influxdb
wget https://dl.influxdata.com/influxdb/releases/influxdb2-2.6.1-amd64.deb
sudo dpkg -i influxdb2-2.6.1-amd64.deb
wget https://dl.influxdata.com/influxdb/releases/influxdb2-client-2.6.1-amd64.deb
sudo dpkg -i influxdb2-client-2.6.1-amd64.deb
rm influxdb2-2.6.1-amd64.deb
rm influxdb2-client-2.6.1-amd64.deb

systemctl enable influxdb
systemctl start influxdb

echo "phpmyadminのセットアップ及びmariadbの設定は自己解決ください"
# ------end------
