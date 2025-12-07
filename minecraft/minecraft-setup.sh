#!/bin/bash

# region : set variables
PAPER_VER=1.21.10
PAPER_NO=117
PAPER_URL=https://api.papermc.io/v2/projects/paper/versions/${PAPER_VER}/builds/${PAPER_NO}/downloads/paper-${PAPER_VER}-${PAPER_NO}.jar
HOSTNAME=$(hostname)
# --------------------

# create update.sh
cat > /root/update.sh <<EOF
#!/bin/bash
sudo apt update
sudo apt -y upgrade
sudo apt -y autoremove
EOF
sudo chmod 700 /root/update.sh
./update.sh

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

# ufw setting
ufw status
echo "y" | ufw enable
ufw default deny
# SSH
ufw allow from 192.168.15.0/24 to any port 22
# minecraft exporter
ufw allow from 192.168.15.0/24 to any port 9225
# node exporter
ufw allow from 192.168.15.0/24 to any port 9100
# minecraft
ufw allow 25565
ufw reload

# install nas mount
apt install -y cifs-utils
apt install -y autofs
systemctl enable autofs
systemctl start autofs
# create minecraft derectory
mkdir /minecraft
mkdir /minecraft/paper
mkdir /minecraft/paper/config
mkdir /minecraft/nas
mkdir /minecraft/paper/plugins
mkdir /minecraft/paper/Backups

# ------minecraft setup------
# paper.jar download
wget -P /minecraft/paper $PAPER_URL
# eula set
cat > /minecraft/paper/eula.txt << EOF
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.m>
$(date +"#%a %b %d %H:%M:%S %Z %Y")
eula=true
EOF

cat > /minecraft/paper/mc-start.sh << EOF
#!/bin/bash
# region : set variables
JARFILE=/minecraft/paper/paper-${PAPER_VER}-${PAPER_NO}.jar
MINMEM=500M
MAXMEM=2048M
SCREEN_NAME=paper
# endregion

# start minecraft
cd \$(dirname \$0)
screen -AdmS \${SCREEN_NAME} java -server -Xms\${MINMEM} -Xmx\${MAXMEM} -jar \${JARFILE} nogui
EOF
chmod 700 /minecraft/paper/mc-start.sh

cat > /minecraft/paper/mc-stop.sh << EOF
#!/bin/bash
# ----- region -----
WAIT=60
STARTSCRIPT=/minecraft/paper/mic-start.sh
SCREEN_NAME='paper'
MINECRAFT_WORLD=/minecraft/paper
# --- endregion ----

cd \$(dirname \$0)
# world messsage
screen -p 0 -S \${SCREEN_NAME} -X eval 'stuff "say '\${WAIT}'秒後にサーバーを停止し、バックアップ作業 に入ります\015"'
screen -p 0 -S \${SCREEN_NAME} -X eval 'stuff "say 10分後に再接続可能になるので、しばらくお待ち下さい\015"'
sleep \${WAIT}
# minecraft stop cmd
screen -p 0 -S \${SCREEN_NAME} -X eval 'stuff "stop\015"'
# minecraft restart
$STARTSCRIPT
EOF
chmod 700 /minecraft/paper/mc-stop.sh
echo "---end---"
