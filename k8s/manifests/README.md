# applicationセットアップ<br>
k8scluster構築後のセットアップについて示します。<br>

- ArgoCDの導入
- application錬成
- ArgoCD認証パスワードの変更
- ArgoCD初期認証情報削除
- pod内ログイン方法


## 1. ArgoCDの導入
公式githubrepositoryからArgoCDをデプロイし、本リポジトリのapps配下のmanifestから各種applicationを錬成します<br>

- ArgoCLIのインストール
- namespaceの作成
- ArgoCDを公式manifestから投入

```bash
# onp-k8s-cp-1にArgoCLIのインストール
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
# namespaceの作成
kubectl create namespace argocd
# ArgoCDを公式manifestから投入
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
## 2. application錬成
本GitHubに登録されているmanifest関連をapplication経由で読込をさせる<br>          
```bash
kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/apps/root/app-of-apps.yaml
```

## 3. ArgoCD認証パスワードの変更
ArgoCDのデプロイ完了後、パスワードを取得しログイン

```bash
# Argo CDの初期管理者パスワードを取得
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# Argo CDにログイン
echo "y" | argocd login 192.168.15.60 --username=admin --password=$PASSWORD
# パスワード変更
argocd account update-password --current-password $PASSWORD
```
## 4. ArgoCD初期認証情報削除
```bash
kubectl -n argocd delete secret/argocd-initial-admin-secret
```

## 5. pod内ログイン方法
以下のコマンドでリモートログインが可能
```bash
kubectl exec -it <pod-name> -- /bin/bash
```

### 全体構成図<br>
* ArgoCDによる錬成後以下のような収容となる
  ![収容時](https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/kubanetesu.svg)
