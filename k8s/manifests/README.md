## 初回動作<br>
k8scluster構築後のセットアップについて示します。<br>

### metallbのセットアップ<br>
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/apps/cluster-wide-apps/metallb/metallb-native.yaml
    sleep 60s
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/apps/cluster-wide-apps/metallb/metallb-address-pool.yaml

### argocdのセットアップ<br>
    # Argo CD CLIをインストール
    ssh onp-k8s-cp-1 curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    ssh onp-k8s-cp-1 sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    ssh onp-k8s-cp-1 rm argocd-linux-amd64
    
    # namespaceを作成
    ssh onp-k8s-cp-1 kubectl create namespace argocd
    ssh onp-k8s-cp-1 kubectl create namespace cluster-wide-apps
    
    # helm chart repo update
    ssh onp-k8s-cp-1 helm repo add argo https://argoproj.github.io/argo-helm
    ssh onp-k8s-cp-1 helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    ssh onp-k8s-cp-1 helm install argocd argo/argo-cd -n argocd --values https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/argocd-apps-helm-chart-values.yaml
    
    sleep 60s
    
    # service is lordbalancer
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/apps/cluster-wide-apps/argocd/argocd-server-lb.yaml
    
    # argocd PW
    echo "argocdのパスワードはこちら" 
    ssh onp-k8s-cp-1 kubectl -n argocd get secret/argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

### argocdのログイン情報変更<br>
* onp-k8s-cp-1にsshログイン<br>

      ssh onp-k8s-cp-1 
* argocdCLIからのログイン<br>

      argocd login 192.168.15.60
* パスワード変更<br>

      argocd account update-password
   
### repo投入
* githubに格納された各種manifest情報をargocdに格納

      argocd app create apps \
        --repo https://github.com/maron-gt123/k8s-setup-for-proxmox.git \
        --path  k8s/apps/root\
        --dest-server https://kubernetes.default.svc \
        --revision main \
        --sync-policy automated \
        --dest-namespace argocd


### dashboard認証コードの表示<br>
    kubectl -n kubernetes-dashboard create token admin-user