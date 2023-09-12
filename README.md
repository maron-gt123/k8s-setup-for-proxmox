# proxmox基盤をベースとした様々な仮想環境の構築<br>
自身の自宅サーバーで使用するproxmox及びVM配下で動作するk8s及びマイクラ環境について記載します。<br>
活用内容としては、マインクラフトのサーバー環境構築及び空きリソースを活用した検証用の位置づけとなります。

## 前提条件<br>
### proxmox<br>
![概要図](https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/maronhome%20in%20kubernetes%20Cloud.svg)
* Proxmox Virtual Environment 8.0.4
  * ベアメタル3ノード運用
  * cluster構成を必須とする
* QNAP TS-253D
  * iSCSI領域として使用
* Ubuntu 22.04 LTS (cloud-init image)
  * kubernetes VMのベースとして使用
  * minecraft VMのベースとして使用
* Network Addressing
  * management Network Segment(1G) (192.168.10.0/24)
  * cluster Network Segment(1G) (192.168.1.0/24)
  * Service Network Segment(1G) (192.168.15.0/24)
  * Storage Network Segment(10G) (192.168.6.0/24)
### k8s(proxmoxのVMとして動作)<br>
* Internal
  * Pod Network (10.128.0.0/16)
  * Service Network (10.96.0.0/16)
* External
  * Node IP
    * Service Network (192.168.15.0/24)
    * Storage Network (192.168.6.0/24)
    * API Endpoint (192.168.6.100)
    * LoadBalancer VIP (192.168.15.50-192.168.15.80)
## proxmoxのインストール<br>
* proxmoxのインストールについては以下からインストーラーを入手[proxmox_en](https://www.proxmox.com/en/)
* インストール時の設定
 * proxmoxのbridge network設定
   * hostname
     * onp-prox01-SV
     * network
       * management：vmbr10(192.168.10.141)
       * cluster：vmbr1(192.168.1.141)
       * service：vmbr15(192.168.15.141)
       * storage：vmbr6(192.168.6.141)
       * gateway:192.168.15.1
   * hostneme
     * onp-prox02-SV
     * network
       * cluster：vmbr1(192.168.1.142)
       * service：vmbr15(192.168.15.142)
       * storage：vmbr6(192.168.6.142)
   * hostname
     * onp-prox03-SV
     * network
       * cluster：vmbr1(192.168.1.143)
       * service：vmbr15(192.168.15.143)
       * storage：vmbr6(192.168.6.143)

## インストール後の設定
### repositoryの変更
* 以下のようにrepository情報を修正

      #proxmox-enterprise-repository disable
      cat > /etc/apt/sources.list.d/pve-enterprise.list << EOF
      #deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise
      EOF
      
      # proxmox-No-Subscription-repository add
      cat > /etc/apt/sources.list << EOF
      deb http://ftp.debian.org/debian bullseye main contrib
      deb http://ftp.debian.org/debian bullseye-updates main contrib

      # PVE pve-no-subscription repository provided by proxmox.com,
      # NOT recommended for production use
      deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
      
      # security updates
      deb http://security.debian.org/debian-security bullseye-security main contrib
      EOF

### MegaRAIDドライバの導入
* 以下scriptでMegaRAIDドライバを導入

      # ---region---
      MEGARAIDURL=https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
      # ------------
      
      # zip install
      apt install libncurses5 unzip alien
      
      # wget Mega-CLI
      wget $MEGARAIDURL
      
      # unzip
      unzip 8-07-14_MegaCLI.zip

      # create debian package
      cd Linux
      alien MegaCli-8.07.14-1.noarch.rpm

      # install debian package
      dpkg -i megacli_8.07.14-2_all.deb
      
      # run
      /opt/MegaRAID/MegaCli/MegaCli64 -h
      /opt/MegaRAID/MegaCli/MegaCli64 -AdpCount
      /opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -aALL
      
      # echo
      echo "RAID情報の確認が取れない場合は以下参照(https://gist.github.com/fxkraus/595ab82e07cd6f8e057d31bc0bc5e779)"

### NFSサーバをproxmoxに導入
* onp-proxmox02及びonp-proxmxo03にNFSサーバを構築
  * onp-proxmox02
    * snippets及びubuntu22.04のOSインストールデータ格納
  * onp-proxmox03
    * backup格納用

          # nfs-kernel-serverをインストール
          ssh prox02 apt-get install nfs-kernel-server
          ssh prox03 apt-get install nfs-kernel-server
          
          # exports設定
          # ssh prox02
          cat >> /etc/exports <<EOF
          # nfs config
          /mnt/pve/prox02 192.168.6.0/24(rw,sync,no_all_squash,no_root_squash,no_subtree_check)
          EOF
          # ssh prox03
          cat >> /etc/exports <<EOF
          # nfs config
          /mnt/pve/prox03 192.168.6.0/24(rw,sync,no_all_squash,no_root_squash,no_subtree_check)
          EOF
