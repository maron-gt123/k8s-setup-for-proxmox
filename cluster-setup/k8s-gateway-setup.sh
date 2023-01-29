# region : create update.sh
cat > update.sh <<EOF
#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
EOF

chmod 700 update.sh

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

ssh_additional_config=$(cat <<EOF
Host onp-k8s-cp-1
   HostName 192.168.8.81
   User cloudinit
   IdentityFile /rsa/k8s_rsa

 Host onp-k8s-cp-2
   HostName 192.168.8.82
   User cloudinit
   IdentityFile /rsa/k8s_rsa

 Host onp-k8s-cp-3
   HostName 192.168.8.83
   User cloudinit
   IdentityFile /rsa/k8s_rsa

 Host onp-k8s-wk-1
   HostName 192.168.8.84
   User cloudinit
   IdentityFile /rsa/k8s_rsa

 Host onp-k8s-wk-2
   HostName 192.168.8.85
   User cloudinit
   IdentityFile /rsa/k8s_rsa

 Host onp-k8s-wk-3
   HostName 192.168.8.86
   User cloudinit
   IdentityFile /rsa/k8s_rsa
   EOF
)

echo "${ssh_additional_config}" >> ~/.ssh/config

cat > ssh-key.sh <<EOF
#!/bin/bash
ssh-keygen -R 192.168.8.81
ssh-keygen -R 192.168.8.82
ssh-keygen -R 192.168.8.83
ssh-keygen -R 192.168.8.84
ssh-keygen -R 192.168.8.85
ssh-keygen -R 192.168.8.86
EOF

chmod 700 update.sh
./ssh-key.sh
