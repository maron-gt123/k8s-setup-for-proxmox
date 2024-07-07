## applicationセットアップ<br>
k8scluster構築後のセットアップについて示します。<br>

### ArgoCDの導入<br>
* 公式githubrepositoryからArgoCDをデプロイし、本リポジトリのapps配下のmanifestから各種applicationを錬成します。
  * 手順については以下の順序となります。
    * SSHログイン
    
          # SSHログイン
          ssh onp-k8s-cp-1
          
    * ArgoCLIのインストール
    * namespaceの作成
    * ArgoCDを公式manifestから投入
    * appを投入
          
          # onp-k8s-cp-1にArgoCLIのインストール
          curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
          sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
          rm argocd-linux-amd64
          
          # namespaceの作成
          ## argocd
          kubectl create namespace argocd
           
          # argocdデプロイ
          kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
          
          sleep 60
          #app-of-apps.yaml apply
          kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/apps/root/app-of-apps.yaml

### ArgoCD認証パスワードの変更
* ArgoCDのデプロイ完了後、パスワードを取得しログイン

      # Argo CDの初期管理者パスワードを取得
      PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
      # Argo CDにログイン
      echo "y" | argocd login 192.168.15.60 --username=admin --password=$PASSWORD
      # パスワード変更
      argocd account update-password --current-password $PASSWORD

* ArgoCDの初期パスワードを削除

      kubectl -n argocd delete secret/argocd-initial-admin-secret

### dashboard認証コードの表示<br>
* k8sdashboardのデプロイ完了後、以下のpashを取得しログイン

      kubectl -n kubernetes-dashboard create token admin-user
### pod内へのリモートアクセス<br>
* 以下のコマンドでリモートログインが可能

      kubectl exec -it <pod-name> -- /bin/bash

### 全体構成図<br>
* ArgoCDによる錬成後以下のような収容となる
  ![収容時](https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/kubanetesu.svg)
