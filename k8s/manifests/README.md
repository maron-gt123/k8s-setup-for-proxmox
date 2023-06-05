## applicationセットアップ<br>
k8scluster構築後のセットアップについて示します。<br>

### ArgoCDの導入<br>
* helmchartを活用しArgoCDをデプロイし、本リポジトリのapps配下のmanifestから各種applicationを錬成します。
  * 手順については以下の順序となります。
    * SSHログイン
    
          # SSHログイン
          ssh onp-k8s-cp-1
          
    * ArgoCLIのインストール
    * helm repo listの追加　※argocd経由でデプロイするkube-prometheus-stackのため
    * namespaceの作成
    * ArgoCDを公式manifestから投入
          
          # onp-k8s-cp-1にArgoCLIのインストール
          curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
          sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
          rm argocd-linux-amd64
          
          # helm repo listの追加
          ## prometheus-community repo
          helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          
          # namespaceの作成
          ## argocd
          kubectl create namespace argocd
           
          # argocdデプロイ
          kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
          
          sleep 60
          #app-of-apps.yaml apply
          kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/apps/root/app-of-apps.yaml

### ArgoCD認証パスワードの表示
* ArgoCDのデプロイ完了後、パスワードを取得しログイン

      # Argo CDの初期管理者パスワードを取得
      PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
      # Argo CDにログイン
      echo "y" | argocd login 192.168.15.60 --username=admin --password=$PASSWORD
      # パスワード変更
      argocd account update-password --current-password $PASSWORD

### dashboard認証コードの表示<br>
* k8sdashboardのデプロイ完了後、以下のpashを取得しログイン

      ssh onp-k8s-cp-1 kubectl -n kubernetes-dashboard create token admin-user
