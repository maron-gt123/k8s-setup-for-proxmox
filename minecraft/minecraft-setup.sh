#!/bin/bash

# region : set variables
PAPER_VER=1.20.1
PAPER_JAR=paper-1.20.1-18.jar
PAPER_URL=https://api.papermc.io/v2/projects/paper/versions/${PAPER_VER}/builds/18/downloads/${PAPER_JAR}
HOSTNAME=$(hostname)

# endregion

# region : create update.sh
cat > update.sh <<EOF
#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
EOF

sudo chmod 700 update.sh

./update.sh
# endregion


# region : setting ntp
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
NTP=ntp-dns.micnet
#FallbackNTP=ntp.ubuntu.com
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
EOF

systemctl restart systemd-timesyncd
timedatectl timesync-status
# endregion


# region : setting timezone Asia/Tokyo
timedatectl set-timezone Asia/Tokyo
timedatectl
# endregion

cd

# region : install　java openjdk
apt install openjdk-17-jre -y
# endregion

# region : install　zip 
apt install zip -y
# endregion

# region : create　minecraft derectory
mkdir /minecraft
mkdir /minecraft/paper
mkdir /minecraft/nas
mkdir /minecraft/paper/plugins
mkdir /minecraft/paper/Backups
# endregion

# region : install nas mount
apt install cifs-utils -y
apt install autofs -y
systemctl enable autofs
systemctl start autofs
# endregion

# region : ufw setting
ufw status
echo "y" | ufw enable
ufw default deny
ufw allow from 192.168.15.0/24 to any port 22
ufw allow from 192.168.15.0/24 to any port 9225
ufw allow 25565
ufw reload
# endregion

# region : minecraft setup
cd /minecraft/paper
sudo wget $PAPER_URL
cat > /minecraft/paper/eula.txt <<EOF
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.m>
$(date +"#%a %b %d %H:%M:%S %Z %Y")
eula=true
EOF

if [ $HOSTNAME = "mic-lobby-SV" ]; then
    cd /minecraft/paper/
    sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-lobby-SV/bukkit.yml
    sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-lobby-SV/server.properties
    sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-lobby-SV/spigot.yml
    cd
else
    cd /minecraft/paper/
    sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-paper/server.properties
    sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-paper/spigot.yml
    cd
fi

cd /minecraft/paper/
sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-start.sh
sudo wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/minecraft/script/mic-stop.sh
chmod 700 mic-start.sh
chmod 700 mic-stop.sh
cd 

chmod 700 /minecraft/paper/mic-start.sh
chmod 700 /minecraft/paper/mic-stop.sh

# endregion

echo --end--

