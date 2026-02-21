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
          kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/apps/root/haramis-server-app.yaml

### ArgoCD認証パスワードの変更
* ArgoCDのデプロイ完了後、パスワードを取得しログイン

```bash
ARGOCD_ADMIN_PASSWORD='Admin123!' && \
HASHED_PASSWORD=$(htpasswd -nbBC 10 "" ${ARGOCD_ADMIN_PASSWORD} | tr -d ':\n') && \
kubectl -n argocd patch secret argocd-secret \
-p "{\"stringData\": {
\"admin.password\": \"${HASHED_PASSWORD}\",
\"admin.passwordMtime\": \"$(date +%FT%T%Z)\"
}}" && \
kubectl -n argocd rollout restart deployment argocd-server
```

* ArgoCDの初期パスワードを削除

```bash
kubectl -n argocd delete secret/argocd-initial-admin-secret
```

### dashboard認証コードの表示<br>
* k8sdashboardのデプロイ完了後、以下のpashを取得しログイン

```bash
kubectl -n kubernetes-dashboard create token admin-user
```
### pod内へのリモートアクセス<br>
* 以下のコマンドでリモートログインが可能
```bash
kubectl exec -it <pod-name> -- /bin/bash
```

### 全体構成図<br>
* ArgoCDによる錬成後以下のような収容となる
  ![収容時](https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/kubanetesu.svg)
