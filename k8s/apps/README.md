## 初回動作<br>
k8scluster構築後のセットアップについて示します。<br>

### metallbのセットアップ<br>
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/metallb/metallb-native.yaml
    sleep 40s
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/metallb/metallb-address-pool.yaml


### dashboard認証コードの表示<br>
    ssh onp-k8s-cp-1 kubectl -n kubernetes-dashboard create token admin-user

### argocdのセットアップ<br>
    # Argo CD CLIをインストール
    ssh onp-k8s-cp-1 curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    ssh onp-k8s-cp-1 sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    ssh onp-k8s-cp-1 rm argocd-linux-amd64
    
    # namespaceを作成
    ssh onp-k8s-cp-1 kubectl create namespace argocd
    
    # helm chart repo update
    ssh onp-k8s-cp-1 helm repo add argo https://argoproj.github.io/argo-helm
    ssh onp-k8s-cp-1 helm install -n argocd argocd argo/argo-cd
    
    # service is lordbalancer
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/apps/cluster-wide-apps/argocd/argocd-server-lb.yaml
    
    # argocd PW
    echo "argocdのパスワードはこちら" 
    ssh onp-k8s-cp-1 kubectl -n argocd get secret/argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

### argocdのログイン情報変更<br>
* argocdCLIからのログイン<br>
       argocd login 192.168.15.60
