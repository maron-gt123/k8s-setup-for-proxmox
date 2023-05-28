## applicationセットアップ<br>
k8scluster構築後のセットアップについて示します。<br>

### ArgoCDの導入<br>
* helmchartを活用しArgoCDをデプロイし、本リポジトリのapps配下のmanifestから各種applicationを錬成します。
  * 手順については以下の順序となります。
    * SSHログイン
    
          # SSHログイン
          ssh onp-k8s-cp-1
          
    * ArgoCLIのインストール
    * helm repo listの追加
    * namespaceの作成
    * ArgoCDをhelmrepoから投入
          
          # onp-k8s-cp-1にArgoCLIのインストール
          curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
          sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
          rm argocd-linux-amd64
          
          # helm repo listの追加
          ## ArgoCD repo
          helm repo add argo https://argoproj.github.io/argo-helm
          ## prometheus-community repo
          helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          
          # namespaceの作成
          ## cluster-wide-apps
          kubectl create namespace cluster-wide-apps
          
          # ArgoCDをhelmrepoから投入
          helm install argocd argo/argo-cd \
              --version 5.5.4 \
              --create-namespace \
              --namespace argocd \
              --values https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/argocd-helm-chart-values.yaml

### ArgoCD認証パスワードの表示
* ArgoCDのデプロイ完了後、パスワードを取得しログイン。

      ssh onp-k8s-cp-1 kubectl -n argocd get secret/argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

### dashboard認証コードの表示<br>
* k8sdashboardのデプロイ完了後、以下のpashを取得しログイン。

      ssh onp-k8s-cp-1 kubectl -n kubernetes-dashboard create token admin-user
