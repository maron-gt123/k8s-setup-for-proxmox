#Kubernetes clusterに Argo CDをインストール

##namespaceを作成

    kubectl create namespace argocd
    
#helm chartによるデプロイ

    helm repo add argo https://argoproj.github.io/argo-helm
    helm install -n argocd argocd argo/argo-cd
    
#service設定
