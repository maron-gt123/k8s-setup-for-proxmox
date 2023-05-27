## applicationセットアップ<br>
k8scluster構築後のセットアップについて示します。<br>

### ArgoCDの導入<br>
* helmchartを活用しArgoCDをデプロイし、本リポジトリのapps配下のmanifestから各種applicationを錬成します。
  * 手順については以下の順序となります。
    * ArgoCLIのインストール
    * helm repo listの追加
    * namespaceの作成
    * ArgoCDをhelmrepoから投入
          
          # onp-k8s-cp-1にArgoCLIのインストール
          ssh onp-k8s-cp-1 curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
          ssh onp-k8s-cp-1 sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
          ssh onp-k8s-cp-1 rm argocd-linux-amd64
          
          # helm repo listの追加
          ## ArgoCD repo
          ssh onp-k8s-cp-1 helm repo add argo https://argoproj.github.io/argo-helm
          ## prometheus-community repo
          ssh onp-k8s-cp-1 helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          
          # namespaceの作成
          ## cluster-wide-apps
          ssh onp-k8s-cp-1 kubectl create namespace cluster-wide-apps
          
          # ArgoCDをhelmrepoから投入
          helm install argocd argo/argo-cd \
              --version 5.5.4 \
              --create-namespace \
              --namespace argocd \
              --values https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/argocd-helm-chart-values.yaml
          helm install argocd argo/argocd-apps \
              --version 0.0.1 \
              --values https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/argocd-apps-helm-chart-values.yaml
