## mariaDBの構築
* minecraftのプラグイン機能群のバックグラウンドとしてSQLを使用する場合があるため、本項で記載する。
* 初期セットアップ
  * 以下のscript実行により一括実行　script[https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/minecraft/sql/setup.sh]
      * apt updateの実行
      * ntpサーバの指定
      * timezoneの設定
      * mariaDBのインストール
      * Apache2のインストール
      * phpのインストール
