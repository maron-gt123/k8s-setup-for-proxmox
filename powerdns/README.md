# PowerDNS 初期セットアップ手順（Raspberry Pi / Debian）
本手順では、PowerDNS を導入する前段階として以下の初期設定を実施します。

- SSH公開鍵登録
- ルートログイン
- 固定IP設定
- 自動アップデートスクリプト作成
- NTP同期設定
- タイムゾーン設定
- UFW ファイアウォール設定
- PowerDNS関連パッケージインストール
- PowerDNSのSQL設定
- poweradmin導入
- nginx設定
- 
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
---
## 3. 固定IPアドレス設定（NetworkManager）
IPアドレスを固定IP化
```bash
nmcli connection modify netplan-eth0 \
ipv4.method manual \
ipv4.addresses 192.168.10.132/24 \
ipv4.gateway 192.168.10.1 \
ipv4.dns "9.9.9.9" \
ipv4.ignore-auto-dns yes
nmcli connection modify netplan-eth0 ipv6.method disabled
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
## 5. NTP同期設定（systemd-timesyncd）
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
## 7. UFW ファイアウォール設定
ファイアーウォールを最小限だけ許可
```bash
apt install -y ufw
echo "y" | ufw enable
ufw default deny
ufw allow from 192.168.10.0/24 to any port 22
ufw allow from 192.168.10.0/24 to any port 80
ufw allow from 192.168.10.0/24 to any port 443
ufw allow 53
```
---
## 8. PowerDNS関連パッケージインストール
以下パッケージをインストールします。

- PowerDNS Authoritative Server
- MySQL Backend
- Recursor
- Nginx
- PHP-FPM

```bash
apt-get install -y \
pdns-server \
pdns-backend-mysql \
mariadb-client \
pdns-recursor \
git \
nginx \
php-fpm \
php-mysql \
php-intl \
php8.4-mysql \
php8.4-intl \
php8.4-xml \
php8.4-gettext \
php8.4-curl \
php8.4-mbstring
```
---
## 9. PowerDNSのSQL設定
PowerDNSの設定ファイルを編集
```bash
nano /etc/powerdns/pdns.conf
```
以下を追加
```bash
launch=gmysql
gmysql-host=192.168.10.131
gmysql-dbname=powerdns
gmysql-user=<pdns_ID>
gmysql-password=<password>
local-port=8053
```
テーブルインポート
```bash
mysql --ssl=0 -u pdns -p -h 192.168.10.131 powerdns < /usr/share/pdns-backend-mysql/schema/schema.mysql.sql
```
その後再起動
```bash
systemctl start pdns
systemctl enable pdns
```
---
## 10. poweradmin導入
dns管理用にpoweradminを導入します<br>
プロジェクトファイルのダウンロードしhtmlに格納   [バージョン管理](https://github.com/poweradmin/poweradmin)

```bash
cd /var/www
git clone https://github.com/poweradmin/poweradmin.git
cd poweradmin
git checkout tags/v****
cd /var/www/html
sudo chown -R www-data:www-data poweradmin
cd
rm -rf /var/www/html/poweradmin/.git
```
---
## 11. nginx設定
nginxの設定ファイルを編集
```bash
nano /etc/nginx/sites-available/poweradmin
```
以下のように設定
```bash
server {
    listen 80;
    server_name _;

    root /var/www/poweradmin;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```
default削除して有効化
```bash
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/poweradmin /etc/nginx/sites-enabled/
```
locale変更
```bash
apt install -y locales
locale-gen ja_JP.UTF-8
update-locale LANG=ja_JP.UTF-8
```
PHP-FPM & nginx起動
```bash
systemctl enable php8.4-fpm
systemctl restart php8.4-fpm
systemctl restart nginx
```
webブラウザアクセス
```bash
http://<ラズパイIP>/install/
```
/install/ で設定した内容を以下に転記
```bash
nano /var/www/poweradmin/config/settings.php
```
/install/ 削除
```bash
rm -rf /var/www/poweradmin/install
systemctl reload nginx
```
---
## 12. Recursor設定
override ディレクトリ作成
 ```bash   
mkdir -p /etc/systemd/system/pdns-recursor.service.d
 ```
 以下記載
 ```bash  
cat > /etc/systemd/system/pdns-recursor.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/sbin/pdns_recursor --config-dir=/etc/powerdns --daemon=no --write-pid=no --disable-syslog --log-timestamp=no
EOF
```
 以下のように設定
 ```bash  
 cat > /etc/powerdns/recursor.yml <<EOF
 dnssec:
  trustanchorfile: /usr/share/dns/root.key

recursor:
  hint_file: /usr/share/dns/root.hints
  include_dir: /etc/powerdns/recursor.d
  security_poll_suffix: ''
  socket_dir: /run/pdns-recursor
  threads: 4

  forward_zones:
    - zone: "mcnet"
      forwarders:
        - 127.0.0.1:8053
    - zone: "maroncloud"
      forwarders:
        - 127.0.0.1:8053
    - zone: "10.168.192.in-addr.arpa"
      forwarders:
        - 127.0.0.1:8053
    - zone: "15.168.192.in-addr.arpa"
      forwarders:
        - 127.0.0.1:8053
  forward_zones_recurse:
    - zone: "."
      forwarders:
        - 9.9.9.9
incoming:
  listen:
    - 192.168.10.132:53
    - 127.0.0.1:53
  allow_from:
    - 192.168.10.0/24
    - 192.168.15.0/24
    - 192.168.1.0/24
    - 127.0.0.1/8
recordcache:
  max_entries: 1000000
  max_negative_ttl: 3600

outgoing:
 # source_address:
 # - 0.0.0.0 # default
webservice:
  webserver: true
  api_key: changeme
  address: 127.0.0.1
  port: 8082
 EOF
 ```
反映
 ```bash   
systemctl daemon-reload
systemctl restart pdns-recursor
 ```