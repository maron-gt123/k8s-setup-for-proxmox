##  PowerDNSを活用したサーバー内名前解決
*  本件では自宅サーバーのバックエンドとして動作している内部DNS(powerdns)について記載

### 設定
*  本scriptを実行し各種依存関係となるソフトをインストール
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
    
    * プロジェクトファイルのダウンロード   [バージョン管理](https://github.com/poweradmin/poweradmin)
 
          git clone https://github.com/poweradmin/poweradmin.git
          cd poweradmin
          git checkout tags/v****
          cd
    * ｄさｖｄｓ 
