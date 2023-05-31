# kubeadmを活用した高可用性kubernetesクラスタの構築<br>
k8sのセットアップ

## VMの錬成<br>
* kubanetesuの構築にあたりCP及びWKをそれぞれ3台構成で錬成する。
  * onp-k8s-cp-1
  * onp-k8s-cp-2
  * onp-k8s-cp-3
  * onp-k8s-wk-1
  * onp-k8s-wk-2
  * onp-k8s-wk-3
* 錬成scriptはこちら[deploy-vm.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/k8s/deploy-vm.sh)
* 削除scriptはこちら[remove-vm.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/k8s/remove-vm.sh)
* 錬成後のsetupはこちら[k8s-node-setup.sh](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/k8s/k8s-node-setup.sh)

## 錬成
* proxmoxホストコンソールで以下の処理を実施しVMを錬成<br>

      TARGET_BRANCH=main
      /bin/bash <(curl -s https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/${TARGET_BRANCH}/k8s/deploy-vm.sh) ${TARGET_BRANCH}

## ping確認
* VM錬成後、pingを実行し疎通確認を実施<br>

      for i in 1 2 3; do ping -c1 k8s-cp$i.micnet; ping -c1 k8s-wk$i.micnet; done


## kubernetesログ確認<br>
* 各VMでk8s-node-setup.shの正常性をログで確認

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

## 全ノードをクラスタ内に参画及びCPノードにkubeconfigを配布<br>
* joinデータを各CP及びWKに共有しクラスタに参画<br>
* CP2及びCP3にkubeconfigを配布し、cluster機能を確立<br>
* 軽い動作check

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
      
      # CP2及びCP3にkubeconfigを配布
      ssh onp-k8s-cp-2 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
      ssh onp-k8s-cp-3 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
      
      # 動作check
      ssh onp-k8s-cp-1 "kubectl get node -o wide && kubectl get pod -A -o wide"
     
## workerにnfsクライアントインストール
    ssh onp-k8s-wk-1 "sudo apt-get install nfs-common -y"
    ssh onp-k8s-wk-2 "sudo apt-get install nfs-common -y"
    ssh onp-k8s-wk-3 "sudo apt-get install nfs-common -y"

## 削除
* proxmoxホストコンソールで以下の処理を実施しVMを削除<br>

      TARGET_BRANCH=main
      /bin/bash <(curl -s https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/${TARGET_BRANCH}/k8s/remove-vm.sh) ${TARGET_BRANCH}

## クラスタの削除後、クラスタの再作成に失敗する場合<br>
クラスタの削除後、同じVMIDでVMを再作成できず、クラスタの作成に失敗することがあります。<br>
これは、クラスタの削除時に複数ノードでコマンドqm destroyが実行された際に、Device Mapperで生成された仮想ディスクデバイスの一部が消えずに残留することがあるためです。<br>

    
    for host in 192.168.1.141 192.168.1.142 192.168.1.143 ; do
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
    
