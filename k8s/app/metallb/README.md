# Kubernetes clusterに metallbをインストール

## metallb install Manifest

    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml

## IPレンジの設定

    kubectl apply -f https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/metallb/ipaddresspool.yaml
