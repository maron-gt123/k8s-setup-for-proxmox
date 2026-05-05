# kubeadmを用いた高可用性Kubernetesクラスタ構築
本ドキュメントでは、前述のProxmox環境上にkubeadmを用いたHA構成のKubernetesクラスタ を構築する手順を示す

## 構成概要
### node構成
| ロール           | ホスト名         |
| ------------- | ------------ |
| Control Plane | onp-k8s-cp-1 |
| Control Plane | onp-k8s-cp-2 |
| Control Plane | onp-k8s-cp-3 |
| Worker Plane  | onp-k8s-wk-1 |
| Worker Plane  | onp-k8s-wk-2 |
| Worker Plane  | onp-k8s-wk-3 |

## VM作成
### 使用スクリプト

- 作成　[deploy-vm.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/k8s/deploy-vm.sh)
- 削除 [remove-vm.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/k8s/remove-vm.sh)
- 初期セットアップ [k8s-node-setup.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/k8s/k8s-node-setup.sh)

## VM作成実行
### 作成スクリプト実行
Proxmoxホスト上で以下実行
```bash
TARGET_BRANCH=main
/bin/bash <(curl -s https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/${TARGET_BRANCH}/k8s/deploy-vm.sh) ${TARGET_BRANCH}
```

### 疎通確認
全nodeへの通信確認
```bash
for i in 1 2 3 4 5 6; do ping -c1 192.168.15.8$i; done
```

### 初期セットアップログ確認
cloud-initおよびセットアップスクリプトの実行結果を確認
```bash
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
```

## クラスタ構築（node参加）
- Control Planeノード参加
- Workerノード参加
- kubeconfig配布
- 動作確認

```bash
# Control Planeノード参加
# join_kubeadm_cp.yaml を onp-k8s-cp-2 と onp-k8s-cp-3 にコピー
scp -3 onp-k8s-cp-1:~/join_kubeadm_cp.yaml onp-k8s-cp-2:~/
scp -3 onp-k8s-cp-1:~/join_kubeadm_cp.yaml onp-k8s-cp-3:~/
# join_kubeadm_cp.yaml を 書き換え
ssh onp-k8s-cp-1 "sed -i 's/abcdefg/192.168.6.81/g' ~/join_kubeadm_cp.yaml"
ssh onp-k8s-cp-2 "sed -i 's/abcdefg/192.168.6.82/g' ~/join_kubeadm_cp.yaml"
ssh onp-k8s-cp-3 "sed -i 's/abcdefg/192.168.6.83/g' ~/join_kubeadm_cp.yaml"
# onp-k8s-cp-2 と onp-k8s-cp-3 で kubeadm join
ssh onp-k8s-cp-2 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
ssh onp-k8s-cp-3 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"

# Workerノード参加
# join_kubeadm_wk.yaml を onp-k8s-wk-1 と onp-k8s-wk-2 と onp-k8s-wk-3 にコピー
scp -3 onp-k8s-cp-1:~/join_kubeadm_wk.yaml onp-k8s-wk-1:~/
scp -3 onp-k8s-cp-1:~/join_kubeadm_wk.yaml onp-k8s-wk-2:~/
scp -3 onp-k8s-cp-1:~/join_kubeadm_wk.yaml onp-k8s-wk-3:~/
# join_kubeadm_wk.yaml を 書き換え
ssh onp-k8s-wk-1 "sed -i 's/abcdefg/192.168.6.84/g' ~/join_kubeadm_wk.yaml"
ssh onp-k8s-wk-2 "sed -i 's/abcdefg/192.168.6.85/g' ~/join_kubeadm_wk.yaml"
ssh onp-k8s-wk-3 "sed -i 's/abcdefg/192.168.6.86/g' ~/join_kubeadm_wk.yaml"
# onp-k8s-wk-1 と onp-k8s-wk-2 と onp-k8s-wk-3 で kubeadm join
ssh onp-k8s-wk-1 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
ssh onp-k8s-wk-2 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
ssh onp-k8s-wk-3 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"

# kubeconfig配布
# CP2及びCP3にkubeconfigを配布
ssh onp-k8s-cp-2 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
ssh onp-k8s-cp-3 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

# 動作確認
echo ""
echo "---------------------------------- node ----------------------------------"
ssh onp-k8s-cp-1 "kubectl get node -o wide"
echo ""
echo "---------------------------------- pod ----------------------------------"
ssh onp-k8s-cp-2 "kubectl get pod -A -o wide"
echo ""
echo "---------------------------------- service ----------------------------------"
ssh onp-k8s-cp-3 "kubectl get service -A -o wide"
```

## 削除
Proxmoxホスト上で以下実行
```bash
TARGET_BRANCH=main
/bin/bash <(curl -s https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/${TARGET_BRANCH}/k8s/remove-vm.sh) ${TARGET_BRANCH}
```

## クラスタ再作成時の注意点
クラスタ削除後、同一VMIDで再作成できない場合がある<BR>
原因は Device Mapperのデバイス残留

以下で強制削除
 ```bash   
for host in 192.168.6.141 192.168.6.142 192.168.6.143 ; do
# Cloudinitデータ削除
ssh $host dmsetup remove vg01-vm--801--cloudinit
ssh $host dmsetup remove vg01-vm--802--cloudinit
ssh $host dmsetup remove vg01-vm--803--cloudinit
ssh $host dmsetup remove vg01-vm--881--cloudinit
ssh $host dmsetup remove vg01-vm--882--cloudinit
ssh $host dmsetup remove vg01-vm--883--cloudinit
# diskデータ削除
ssh $host dmsetup remove vg01-vm--801--disk--0
ssh $host dmsetup remove vg01-vm--802--disk--0
ssh $host dmsetup remove vg01-vm--803--disk--0
ssh $host dmsetup remove vg01-vm--881--disk--0
ssh $host dmsetup remove vg01-vm--882--disk--0
ssh $host dmsetup remove vg01-vm--883--disk--0
done
```    