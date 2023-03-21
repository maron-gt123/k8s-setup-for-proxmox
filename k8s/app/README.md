##Helmチャートのリポジトリを追加<br>

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
##  kube-prometheus-stackを以下のコマンドでインストール<br>
    helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --install --version 33.2.0 \
    --namespace prometheus --create-namespace \
    --set grafana.ingress.enabled=true \
    --set grafana.ingress.ingressClassName=nginx \
    --wait
