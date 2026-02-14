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
# PowerDNS 設定
以降では、PowerDNS設定を実施します。

- PowerDNSのSQL設定
- poweradmin導入
- nginx設定
---
## 1. PowerDNSのSQL設定
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
その後再起動
```bash
systemctl start pdns
systemctl enable pdns
systemctl restart php8.4-fpm
systemctl restart nginx
```
---
## 2. poweradmin導入
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
## 3. nginx設定
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
PHP-FPM 起動
```bash
systemctl enable php8.4-fpm
systemctl restart php8.4-fpm
```
Nginx 再起動
```bash
systemctl restart nginx
```
webブラウザアクセス
```bash
http://<ラズパイIP>/install/
```
---

 ```bash   
allow-from=192.168.10.0/24, 192.168.15.0/24, 192.168.1.0/24
forward-zones=mcnet=127.0.0.1:8053, maroncloud=127.0.0.1:8053, 10.168.192.in-addr.arpa=127.0.0.1:8053, 15.168.192.in-addr.arpa=127.0.0.1:8053
forward-zones-recurse=.=9.9.9.9
local-address=192.168.10.132, 127.0.0.1
local-port=53
threads=4
max-cache-entries=1000000
max-negative-ttl=3600
```
