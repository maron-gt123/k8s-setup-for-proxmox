##  PowerDNSを活用したサーバー内名前解決
*  本件では自宅サーバーのバックエンドとして動作している内部DNS(powerdns)について記載

### 設定
*  本scriptを実行し各種依存関係となるソフトをインストール   [script](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/powerdns/setup.sh)
*  script実行後各種設定を実施とする前提条件は以下
   *  powerdns:4.7.3
   *  poweradmin:3.7.0
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
