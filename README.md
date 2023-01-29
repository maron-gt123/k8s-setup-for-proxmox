# kubernetesの各種セットアップ方法を記載

## gatewayの設定<br>

## clusterの設定<br>
以下のscriptを使用しkubeadm等をインストール<br>
[script](https://github.com/maron-gt123/kubanetesu-cluster-setup/blob/main/cluster-setup/k8s-node-setup.sh)
### kubernetesログ確認<br>
     ssh onp-k8s-cp-1 "sudo cat /var/log/cloud-init-output.log"
     ssh onp-k8s-cp-2 "sudo cat /var/log/cloud-init-output.log"
     ssh onp-k8s-cp-3 "sudo cat /var/log/cloud-init-output.log"
     ssh onp-k8s-wk-1 "sudo cat /var/log/cloud-init-output.log"
     ssh onp-k8s-wk-2 "sudo cat /var/log/cloud-init-output.log"
     ssh onp-k8s-wk-3 "sudo cat /var/log/cloud-init-output.log"
     
     ## cloud-final.service - Execute cloud user/final scripts
     ## k8s-node-setup.sh などのログはここにあります
     ssh onp-k8s-cp-1 "sudo journalctl -u cloud-final.service"
     ssh onp-k8s-cp-2 "sudo journalctl -u cloud-final.service"
     ssh onp-k8s-cp-3 "sudo journalctl -u cloud-final.service"
     ssh onp-k8s-wk-1 "sudo journalctl -u cloud-final.service"
     ssh onp-k8s-wk-2 "sudo journalctl -u cloud-final.service"
     ssh onp-k8s-wk-3 "sudo journalctl -u cloud-final.service"
## 全ノードをクラスタ内に参画<br>
     # join_kubeadm_cp.yaml を onp-k8s-cp-2 と onp-k8s-cp-3 にコピー
     scp -3 onp-k8s-cp-1:~/join_kubeadm_cp.yaml onp-k8s-cp-2:~/
     scp -3 onp-k8s-cp-1:~/join_kubeadm_cp.yaml onp-k8s-cp-3:~/
     
     # onp-k8s-cp-2 と onp-k8s-cp-3 で kubeadm join
     ssh onp-k8s-cp-2 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
     ssh onp-k8s-cp-3 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
     
     # join_kubeadm_wk.yaml を onp-k8s-wk-1 と onp-k8s-wk-2 と onp-k8s-wk-3 にコピー
     scp -3 onp-k8s-cp-1:~/join_kubeadm_wk.yaml onp-k8s-wk-1:~/
     scp -3 onp-k8s-cp-1:~/join_kubeadm_wk.yaml onp-k8s-wk-2:~/
     scp -3 onp-k8s-cp-1:~/join_kubeadm_wk.yaml onp-k8s-wk-3:~/
     
     # onp-k8s-wk-1 と onp-k8s-wk-2 と onp-k8s-wk-3 で kubeadm join
     ssh onp-k8s-wk-1 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
     ssh onp-k8s-wk-2 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
     ssh onp-k8s-wk-3 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
## コントロールプレーンの全ノードにkubeconfigを配布
     ssh onp-k8s-cp-2 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
     ssh onp-k8s-cp-3 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
## 動作チェック
     ssh onp-k8s-cp-1 "kubectl get node -o wide && kubectl get pod -A -o wide"
     ssh onp-k8s-cp-2 "kubectl get node -o wide && kubectl get pod -A -o wide"
     ssh onp-k8s-cp-3 "kubectl get node -o wide && kubectl get pod -A -o wide"
