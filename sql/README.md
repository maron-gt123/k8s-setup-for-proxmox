## mariaDBの構築
本手順では、mariaDB を導入する前段階として以下の初期設定を実施します。

- SSH公開鍵登録
- ルートログイン
- 固定IP設定
- 自動アップデートスクリプト作成
- NTP同期・タイムゾーン設定
- UFW ファイアウォール設定
- mariaDB及びphpmyadminパッケージインストール
- phpmyadmin設定
---
## 1. SSH公開鍵登録
公開鍵を取得しSSHの認証をセキュアにかつログインの簡易化
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
curl -sS https://github.com/maron-gt123.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```
---
## 2. rootログイン
以降の設定をrootで実行
```bash
sudo su -
```
## 3. 固定IPアドレス設定（netplan）
IPアドレスを固定IP化 ※install時に設定の場合は不要
```bash
cat > /etc/netplan/50-cloud-init.yaml <<EOF
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        enp1s0:
            addresses:
            - 192.168.10.131/24
            nameservers:
                addresses:
                - 9.9.9.9
                search: []
            routes:
            -   to: default
                via: 192.168.10.1
    version: 2
EOF
# netplan 適応　※SSH接続中の実行時は注意
netplan apply
```
---
## 4. 自動アップデートスクリプト作成
update行為を簡易化
```bash
cat > update.sh <<EOF
#!/bin/bash
sudo apt update
sudo apt -y upgrade
sudo apt -y autoremove
EOF

chmod 700 update.sh
./update.sh
```
---
## 5. NTP同期・タイムゾーン設定
NTPを設定し正確な時刻を取得しtimezoneも日本に
```bash
cat > /etc/systemd/timesyncd.conf <<EOF
[Time]
NTP=ntp.jst.mfeed.ad.jp
EOF
systemctl restart systemd-timesyncd
timedatectl timesync-status
timedatectl set-timezone Asia/Tokyo
timedatectl
```
---
## 6. UFW ファイアウォール設定
ファイアーウォールを最小限だけ許可
```bash
apt install -y ufw
echo "y" | ufw enable
ufw default deny
ufw allow from 192.168.10.0/24 to any port 22
ufw allow from 192.168.10.0/24 to any port 9100
ufw allow from 192.168.10.0/24 to any port 8086
ufw allow from 192.168.10.0/24 to any port 80
ufw allow from 192.168.10.0/24 to any port 3306
```
---
## 7. mariaDB及びphpmyadminパッケージインストール
以下パッケージをインストールします。

- prometheus prometheus-node-exporter
- mariadb-server
- php-fpm
- nginx
- phpmyadmin
```bash
apt-get install -y \
prometheus prometheus-node-exporter \
mariadb-server \
php-fpm \
nginx
```
アクセス許可設定
```bash
nano /etc/mysql/mariadb.conf.d/50-server.cnf
#↓以下に設定
bind-address = 0.0.0.0
```

phpmyadminをインストール<br>
インストール時の設定はApacheを選択しないこと
```bash
apt -y install phpmyadmin
```
---
## 8. phpmyadmin設定
nginxにphpmyadminの設定付与
```bash
nano /etc/nginx/sites-enabled/default
```
以下を追加
```bash
    location /phpmyadmin {
        alias /usr/share/phpmyadmin/;
        index index.php;
    }

    location ~ ^/phpmyadmin/(.+\.php)$ {
        alias /usr/share/phpmyadmin/$1;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /usr/share/phpmyadmin/$1;
    }

    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        alias /usr/share/phpmyadmin/$1;
    }
```
記載後、適応
```bash
nginx -t
systemctl restart nginx
```
ブラウザより以下確認
```bash
http://192.168.10.131/phpmyadmin/
```
---
## 9. mariadb設定
minecraftとpowerdnsのデータベースなので2つのアカウントを作成します<br>
MariaDBにログイン
```bash
mysql -u root -p
```
minecraft用
```bash
CREATE USER '<任意のユーザ名>'@'%' IDENTIFIED BY '<任意のパスワード>' ;
GRANT ALL ON *.* to <任意のユーザ名>@'%' ;
FLUSH PRIVILEGES;
```
powerdns用
```bash
CREATE USER '<任意のユーザ名>'@'<powerdnsホストアドレス>' IDENTIFIED BY '<任意のパスワード>' ;
GRANT ALL PRIVILEGES ON powerdns.* TO '<任意のユーザ名>'@'<powerdnsホストアドレス>';
FLUSH PRIVILEGES;
```
各種datebase作成
```bash
CREATE DATABASE powerdns;
CREATE DATABASE mc_LuckPerms;
```
---