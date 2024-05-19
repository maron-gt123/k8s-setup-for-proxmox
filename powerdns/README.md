##  PowerDNSを活用したサーバー内名前解決
*  本件では自宅サーバーのバックエンドとして動作している内部DNS(powerdns)について記載

### 設定
*  本scriptを実行し各種依存関係となるソフトをインストール   [script](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/powerdns/setup.sh)
*  手動設定
    *  PowerDNSの設定ファイルを編集

           sudo nano /etc/powerdns/pdns.conf
       *  設定内容
          
              launch=gmysql
              gmysql-host=192.168.10.131
              gmysql-dbname=powerdns
              gmysql-user=<pdns_ID>
              gmysql-password=<password>
       
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

          http://<poweradminIPaddress>/poweradmin/
    * Apache2の設定

          sudo nano /etc/apache2/sites-available/poweradmin.conf
      
    * Apache2に以下の設定追記

          <VirtualHost *:80>
              ServerAdmin webmaster@localhost
              DocumentRoot /var/www/html/poweradmin
              ErrorLog ${APACHE_LOG_DIR}/error.log
              CustomLog ${APACHE_LOG_DIR}/access.log combined

              <Directory /var/www/html/poweradmin>
                  Options Indexes FollowSymLinks
                  AllowOverride All
                  Require all granted
              </Directory>
          </VirtualHost>
    * Apache2再起動

          sudo a2ensite poweradmin
          sudo systemctl restart apache2
    * ｄｄ
