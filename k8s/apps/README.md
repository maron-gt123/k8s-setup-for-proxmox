## 初回動作<br>
k8scluster構築後のセットアップについて示します。<br>

### metallbのセットアップ<br>

    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/metallb/metallb-native.yaml
    sleep 40s
    ssh onp-k8s-cp-1 kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/metallb/metallb-address-pool.yaml


### dashboard認証コードの表示
    ssh onp-k8s-cp-1 kubectl -n kubernetes-dashboard create token admin-user
