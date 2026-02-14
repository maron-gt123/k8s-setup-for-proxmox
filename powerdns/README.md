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
php \
php-fpm \
nginx \
php-mysql \
php-intl
```


*  手動設定
    *  PowerDNSの設定ファイルを編集

           sudo nano /etc/powerdns/pdns.conf
       *  設定内容
          
              launch=gmysql
              gmysql-host=192.168.10.131
              gmysql-dbname=powerdns
              gmysql-user=<pdns_ID>
              gmysql-password=<password>
              local-port=8053
       
    *  PowerDNSを起動
    
           sudo systemctl start pdns
           sudo systemctl enable pdns
    
    * プロジェクトファイルのダウンロードしhtmlに格納   [バージョン管理](https://github.com/poweradmin/poweradmin)
 
          cd /var/www/html
          git clone https://github.com/poweradmin/poweradmin.git
          cd poweradmin
          git checkout tags/v****
          cd /var/www/html
          sudo chown -R www-data:www-data poweradmin
          cd
          rm -rf /var/www/html/poweradmin/.git
    * webブラウザアクセス
       * install設定に沿って設定を実施とするが原則mariaDBへのアカウント設定とphpの設定関連

             http://<poweradminIPaddress>/poweradmin/install/
    * install設定完了後のinstalldirectory削除
 
          rm -rf /var/www/html/poweradmin/install

    * Apache2の設定

          cat > /etc/apache2/sites-available/poweradmin.conf <<EOF
          <VirtualHost *:80>
              ServerAdmin webmaster@<IPaddress>
              DocumentRoot /var/www/html/poweradmin
              ErrorLog ${APACHE_LOG_DIR}/error.log
              CustomLog ${APACHE_LOG_DIR}/access.log combined

              <Directory /var/www/html/poweradmin>
                  Options Indexes FollowSymLinks
                  AllowOverride All
                  Require all granted
              </Directory>
          </VirtualHost>
          EOF
    * Apache2再起動

          sudo a2ensite poweradmin
          sudo systemctl restart apache2
    * webGUIへのアクセス
        * 以下画面が表示されれば成功
           * 初期ユーザー名はadmin
      ![スタート画面](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/powerdns/poweradmin_startmonitor.png)
    * recursorの設定
       * /etc/powerdns/recursor.confを編集
     
             allow-from=192.168.10.0/24, 192.168.15.0/24, 192.168.1.0/24
             forward-zones=mcnet=127.0.0.1:8053, maroncloud=127.0.0.1:8053, 10.168.192.in-addr.arpa=127.0.0.1:8053, 15.168.192.in-addr.arpa=127.0.0.1:8053
             forward-zones-recurse=.=9.9.9.9
             local-address=192.168.10.132, 127.0.0.1
             local-port=53
             threads=4
             max-cache-entries=1000000
             max-negative-ttl=3600
       * 設定反映
         
             sudo systemctl restart pdns-recursor
