#!/bin/bash

# region : set variables
PAPER_VER=1.20.6
PAPER_NO=128
PAPER_URL=https://api.papermc.io/v2/projects/paper/versions/${PAPER_VER}/builds/${PAPER_NO}/downloads/paper-${PAPER_VER}-${PAPER_NO}.jar
HOSTNAME=$(hostname)
# --------------------

# create update.sh
cat > update.sh <<EOF
#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
EOF
sudo chmod 700 update.sh
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
# minecraft exporter
# node exporter
# minecraft
ufw allow from 192.168.15.0/24 to any port 22
ufw allow from 192.168.15.0/24 to any port 9225
ufw allow from 192.168.15.0/24 to any port 9100
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


cat > /minecraft/paper/mic-stop.sh << EOF
#!/bin/bash
# ----- region -----
WAIT=60
STARTSCRIPT=/minecraft/paper/mic-start.sh
SCREEN_NAME='paper'
MINECRAFT_WORLD=/minecraft/paper
# --- endregion ----

# world messsage
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "say '${WAIT}'秒後にサーバーを停止し、バックアップ作業 に入ります\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "say 10分後に再接続可能になるので、しばらくお待ち下さい\015"'
sleep $WAIT
# minecraft stop cmd
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "stop\015"'
# minecraft restart
$STARTSCRIPT
EOF
chmod 700 /minecraft/paper/mic-stop.sh
# config download
if [ $HOSTNAME = "mic-lobby-SV" ]; then
    git clone --depth 1 https://github.com/maron-gt123/k8s-setup-for-proxmox.git
    cp -r /home/cloudinit/k8s-setup-for-proxmox/minecraft/config/mic-lobby/world/ /minecraft/paper/
    cp /home/cloudinit/k8s-setup-for-proxmox/minecraft/config/mic-lobby/bukkit.yml /minecraft/paper/
    cp /home/cloudinit/k8s-setup-for-proxmox/minecraft/config/mic-lobby/server.properties /minecraft/paper/
    cp /home/cloudinit/k8s-setup-for-proxmox/minecraft/config/mic-lobby/spigot.yml /minecraft/paper/
    cat > /minecraft/paper/mic-start.sh << EOF
#!/bin/bash
# region : set variables
JARFILE=/minecraft/paper/paper-${PAPER_VER}-${PAPER_NO}.jar
MINMEM=500M
MAXMEM=2048M
SCREEN_NAME=paper
# endregion

# start minecraft
cd `dirname $0`
screen -AdmS ${SCREEN_NAME} java -server -Xms${MINMEM} -Xmx${MAXMEM} -jar ${JARFILE} nogui

# sleep 60s
sleep 60s
# time and water cycle is false
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "gamerule doDaylightCycle false\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "gamerule doWeatherCycle false\015"'

# time and water is set
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "time set day\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "weather clear\015"'
EOF
    chmod 700 /minecraft/paper/mic-start.sh
    rm -r /home/cloudinit/k8s-setup-for-proxmox/
    echo "---end---"
else
    wget -P /minecraft/paper https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/config/mic-paper/server.properties
    wget -P /minecraft/paper https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/config/mic-paper/spigot.yml
    wget -P /minecraft/paper/config https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/config/mic-paper/paper-world-defaults.yml
    wget -P /minecraft/paper/config https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/config/mic-paper/paper-global.yml
    cat > /minecraft/paper/mic-start.sh << EOF
#!/bin/bash
# region : set variables
JARFILE=/minecraft/paper/paper-${PAPER_VER}-${PAPER_NO}.jar
MINMEM=500M
MAXMEM=2048M
SCREEN_NAME=paper
# endregion

# start minecraft
cd `dirname $0`
screen -AdmS ${SCREEN_NAME} java -server -Xms${MINMEM} -Xmx"${MAXMEM}" -jar "${JARFILE}" nogui
EOF
    chmod 700 /minecraft/paper/mic-start.sh
    echo "---end---"
fi
