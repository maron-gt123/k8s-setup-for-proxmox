# Proxmox基盤をベースとした仮想環境構築
本リポジトリでは、自宅サーバー上に構築する Proxmox基盤 を中心に、その上で動作する Kubernetes環境 および Minecraft環境 の構成・手順をまとめる。


## 全体構成
### 接続構成
![概要図](https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/refs/heads/main/%E8%AB%96%E7%90%86%E6%A7%8B%E6%88%90%E5%9B%B3.drawio.svg)


## 前提条件
### proxmox構成

- Proxmox Virtual Environment
  - バージョン: 9.1.9
  - ベアメタル3node
  - cluster構成

- ストレージ
  - QNAP TS-253D

- VMベースイメージ
  - Ubuntu 24.04 LTS (cloud-init)
    - Kubernetesノード用
    - Minecraftサーバ用

- ネットワーク構成

| セグメント      | 用途       | CIDR            | 帯域  |
| ---------- | -------- | --------------- | --- |
| Management | 管理用      | 192.168.10.0/24 | 1G  |
| Service    | サービス通信用  | 192.168.15.0/24 | 1G  |
| Storage    | ストレージ通信用 | 192.168.6.0/24  | 10G |

---
### Kubernetes構成（VM上）
- Internal
  - Pod Network: `10.128.0.0/16`
  - Service Network: `10.96.0.0/16`
- External
  - Node IP
    - Service Network `192.168.15.0/24`
    - Storage Network `192.168.6.0/24`
    - API Endpoint `192.168.6.100`
    - LoadBalancer VIP `192.168.15.50 - 192.168.15.80`

## proxmoxインストール
### インストーラー取得
以下よりダウンロード[proxmox_en](https://www.proxmox.com/en/)

### node設定

#### onp-prox01-SV
- Management: `vmbr10 (192.168.10.141)`
- Service: `vmbr15 (192.168.15.141)`
- Storage: `vmbr6 (192.168.6.141)`

#### onp-prox02-SV
- Service: `vmbr15 (192.168.15.142)`
- Storage: `vmbr6 (192.168.6.142)`

#### onp-prox03-SV
- Service: `vmbr15 (192.168.15.143)`
- Storage: `vmbr6 (192.168.6.143)`

## インストール後設定
### Repository設定変更

```bash
#proxmox-enterprise-repository disable
cat > /etc/apt/sources.list.d/pve-enterprise.list << EOF
#deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF

# proxmox-No-Subscription-repository add
cat > /etc/apt/sources.list << EOF
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib

# Proxmox VE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription

# security updates
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF

# Ceph Quincy No-Subscription Repository
cat > /etc/apt/sources.list.d/ceph.list << EOF
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
EOF
```

### MegaRAIDドライバ導入

```bash
# ---region---
MEGARAIDURL=https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
# ------------
# zip install
apt install libncurses5 unzip alien
 wget Mega-CLI
wget $MEGARAIDURL
# unzip
unzip 8-07-14_MegaCLI.zip
# create debian package
cd Linux
alien MegaCli-8.07.14-1.noarch.rpm
# install debian package
dpkg -i megacli_8.07.14-2_all.deb
ln -s /opt/MegaRAID/MegaCli/MegaCli64 /usr/local/bin/megacli
# echo
echo "RAID情報の確認が取れない場合は以下参照(https://gist.github.com/fxkraus/595ab82e07cd6f8e057d31bc0bc5e779)"
```

### NFSサーバ構築

#### 対象ノード 
- onp-prox02: OSイメージ・snippets用
- onp-prox03: バックアップ用

#### install
```bash
# nfs-kernel-serverをインストール
ssh onp-prox02 apt-get install nfs-kernel-server
ssh onp-prox03 apt-get install nfs-kernel-server
```
#### exports設定

#### onp-prox02
```bash
# exports設定
# ssh prox02
cat >> /etc/exports <<EOF
# nfs config
/mnt/pve/prox02 192.168.6.0/24(rw,sync,no_all_squash,no_root_squash,no_subtree_check)
EOF
```
#### onp-prox03
```bash
# ssh prox03
cat >> /etc/exports <<EOF
# nfs config
/mnt/pve/prox03 192.168.6.0/24(rw,sync,no_all_squash,no_root_squash,no_subtree_check)
EOF
```