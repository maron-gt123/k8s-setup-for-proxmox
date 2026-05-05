# Applicationセットアップ（ArgoCD）
本ドキュメントでは、Kubernetesクラスタ構築後に実施する<BR>
ArgoCDを用いたアプリケーションデプロイ手順を示す

## 概要
以下の手順を実施する

- ArgoCDの導入
- Applicationのデプロイ（App of Apps構成）
- 管理者パスワードの変更
- 初期認証情報の削除
- Podへのアクセス方法



## ArgoCDの導入
公式マニフェストおよび本リポジトリの定義を用いてArgoCDをデプロイする。

```bash
# onp-k8s-cp-1にArgoCLIのインストール
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
# namespaceの作成
kubectl create namespace argocd
# Arco-CDのCRD
kubectl create -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable
# kustomization.yamlから投入
kubectl apply -k https://github.com/maron-gt123/k8s-setup-for-proxmox/k8s/manifests/apps/cluster-wide-apps/argocd?ref=main --server-side --force-conflicts
# 権限付与
kubectl create clusterrolebinding argocd-application-controller-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=argocd:argocd-application-controller
```

## Applicationデプロイ
App of Appsパターンを利用して、本リポジトリ内のマニフェストを一括適用する。      
```bash
kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/apps/root/app-of-apps.yaml
```

## Podへのログイン方法
デバッグ用途でPod内部へアクセスする場合
```bash
kubectl exec -it -n <namespace> <pod-name> -- /bin/bash
```

## 構成イメージ
ArgoCDによるデプロイ後の構成
  ![収容時](https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/manifests/kubanetesu.svg)
