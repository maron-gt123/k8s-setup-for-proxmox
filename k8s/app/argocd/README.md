# Kubernetes clusterに Argo CDをインストール

## Argo CD CLIをインストール
    
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

## namespaceを作成

    kubectl create namespace argocd
    
## helm chartによるデプロイ

    helm repo add argo https://argoproj.github.io/argo-helm
    helm install -n argocd argocd argo/argo-cd
    
#service設定
