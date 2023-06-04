## mariaDBの構築
* minecraftのプラグイン機能群のバックグラウンドとしてSQLを使用する場合があるため、本項で記載する。
* 初期セットアップ
  * 以下のscript実行により一括実行　[script](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/minecraft/sql/setup.sh)
      * apt updateの実行
      * ntpサーバの指定
      * timezoneの設定
      * mariaDBのインストール
      * Apache2のインストール
      * phpのインストール
* mariadbの初期設定
  * 初期設定については手動で設定する。※意図的な変更も加味して
    * 対話型で設定とする
    
          mysql_secure_installation
    * Enter current password for root (enter for none):
      * Ente入力
    * Switch to unix_socket authentication [Y/n]
      * noを入力
    * Change the root password? [Y/n]
      * yesを入力 任意のパスワードを入力
