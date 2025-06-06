#!/usr/bin/env bash

set -eu

# special thanks!: https://gist.github.com/inductor/32116c486095e5dde886b55ff6e568c8

function usage() {
    echo "usage> k8s-node-setup.sh [COMMAND]"
    echo "[COMMAND]:"
    echo "  help        show command usage"
    echo "  onp-k8s-cp-1    run setup script for onp-k8s-cp-1"
    echo "  onp-k8s-cp-2    run setup script for onp-k8s-cp-2"
    echo "  onp-k8s-cp-3    run setup script for onp-k8s-cp-3"
    echo "  onp-k8s-wk-*    run setup script for onp-k8s-wk-*"
}

case $1 in
    onp-k8s-cp-1|onp-k8s-cp-2|onp-k8s-cp-3|onp-k8s-wk-*)
        ;;
    help)
        usage
        exit 255
        ;;
    *)
        usage
        exit 255
        ;;
esac

# Set global variables
TARGET_BRANCH=$2
KUBE_API_SERVER_VIP=192.168.6.100
VIP_INTERFACE=ens19
NODE_IPS=( 192.168.6.81 192.168.6.82 192.168.6.83 )

# set per-node variables
case $1 in
    onp-k8s-cp-1)
        KEEPALIVED_STATE=MASTER
        KEEPALIVED_PRIORITY=101
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[0]}
        KEEPALIVED_UNICAST_PEERS=( "${NODE_IPS[1]}" "${NODE_IPS[2]}" )
        ;;
    onp-k8s-cp-2)
        KEEPALIVED_STATE=BACKUP
        KEEPALIVED_PRIORITY=99
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[1]}
        KEEPALIVED_UNICAST_PEERS=( "${NODE_IPS[0]}" "${NODE_IPS[2]}" )
        ;;
    onp-k8s-cp-3)
        KEEPALIVED_STATE=BACKUP
        KEEPALIVED_PRIORITY=97
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[2]}
        KEEPALIVED_UNICAST_PEERS=( "${NODE_IPS[0]}" "${NODE_IPS[1]}" )
        ;;
    onp-k8s-wk-*)
        ;;
    *)
        exit 1
        ;;
esac

# Install Containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's#sandbox_image = "registry.k8s.io/pause:3.8"#sandbox_image = "registry.k8s.io/pause:3.9"#g' /etc/containerd/config.toml
if grep -q "SystemdCgroup = true" "/etc/containerd/config.toml"; then
echo "Config found, skip rewriting..."
else
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml  
fi

sudo systemctl restart containerd

# Modify kernel parameters for Kubernetes
# inotify instance number is very limited in Ubuntu 24.04 and it has to be at least more than pod number * 2
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.keys.root_maxkeys = 1000000
kernel.keys.root_maxbytes = 25000000
net.ipv4.conf.*.rp_filter = 0
net.ipv4.tcp_fastopen=3
fs.inotify.max_user_watches=65536
fs.inotify.max_user_instances=8192
EOF
sysctl --system

# Install kubeadm
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubeadm=1.32.1-1.1 kubectl=1.32.1-1.1 kubelet=1.32.1-1.1
sudo apt-mark hold kubelet kubectl

# Disable swap
swapoff -a

cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
EOF

# Ends except worker-plane
case $1 in
    onp-k8s-wk-*)
        exit 0
        ;;
    onp-k8s-cp-1|onp-k8s-cp-2|onp-k8s-cp-3)
        ;;
    *)
        exit 1
        ;;
esac

# Install HAProxy
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-3.1 -y
sudo apt-get install -y haproxy=3.1.\*

cat > /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http
frontend k8s-api
    bind ${KUBE_API_SERVER_VIP}:8443
    mode tcp
    option tcplog
    default_backend k8s-api

backend k8s-api
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server k8s-api-1 ${NODE_IPS[0]}:6443 check
    server k8s-api-2 ${NODE_IPS[1]}:6443 check
    server k8s-api-3 ${NODE_IPS[2]}:6443 check
EOF

# Install Keepalived
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sysctl -p

apt-get -y install keepalived

cat > /etc/keepalived/keepalived.conf <<EOF
# Define the script used to check if haproxy is still working
vrrp_script chk_haproxy {
    script "sudo /usr/bin/killall -0 haproxy"
    interval 2
    weight 2
}

# Configuration for Virtual Interface
vrrp_instance LB_VIP {
    interface ${VIP_INTERFACE}
    state ${KEEPALIVED_STATE}
    priority ${KEEPALIVED_PRIORITY}
    virtual_router_id 51

    smtp_alert          # Enable Notifications Via Email

    authentication {
        auth_type AH
        auth_pass zaq12wsx	# Password for accessing vrrpd. Same on all devices
    }
    unicast_src_ip ${KEEPALIVED_UNICAST_SRC_IP} # Private IP address of master
    unicast_peer {
        ${KEEPALIVED_UNICAST_PEERS[0]}		# Private IP address of the backup haproxy
        ${KEEPALIVED_UNICAST_PEERS[1]}		# Private IP address of the backup haproxy
    }

    # The virtual ip address shared between the two loadbalancers
    virtual_ipaddress {
        ${KUBE_API_SERVER_VIP}
    }

    # Use the Defined Script to Check whether to initiate a fail over
    track_script {
        chk_haproxy
    }
}
EOF

# Create keepalived user
groupadd -r keepalived_script
useradd -r -s /sbin/nologin -g keepalived_script -M keepalived_script

echo "keepalived_script ALL=(ALL) NOPASSWD: /usr/bin/killall" >> /etc/sudoers

# Enable VIP services
systemctl enable keepalived --now
systemctl enable haproxy --now

# Reload VIP services
systemctl reload keepalived
systemctl reload haproxy

# Pull images first
kubeadm config images pull

# install k9s
wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Linux_amd64.tar.gz -O - | tar -zxvf - k9s && sudo mv ./k9s /usr/local/bin/

# Ends except first-control-plane
case $1 in
    onp-k8s-cp-1)
        ;;
    onp-k8s-cp-2|onp-k8s-cp-3)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac

# Set kubeadm bootstrap token using openssl
KUBEADM_BOOTSTRAP_TOKEN=$(openssl rand -hex 3).$(openssl rand -hex 8)
KUBEADM_LOCAL_ENDPOINT=$(ip -4 addr show ens19 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | awk 'NR==1{print $1}')

# Set init configuration for the first control plane
cat > "$HOME"/init_kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- token: "$KUBEADM_BOOTSTRAP_TOKEN"
  description: "kubeadm bootstrap token"
  ttl: "24h"
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
  kubeletExtraArgs:
    node-ip: "$KUBEADM_LOCAL_ENDPOINT"
localAPIEndpoint:
  advertiseAddress: "$KUBEADM_LOCAL_ENDPOINT"
  bindPort: 6443
skipPhases:
  - addon/kube-proxy
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  serviceSubnet: "10.96.64.0/18"
  podSubnet: "10.96.128.0/18"
etcd:
  local:
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
kubernetesVersion: "v1.32.0"
controlPlaneEndpoint: "${KUBE_API_SERVER_VIP}:8443"
apiServer:
  certSANs:
  # We are directing the A-record of
  #   k8s-api.onp-k8s.admin.local-tunnels
  # to 127.0.0.1 (see terraform/cloudflare_dns_records.tf for details).
  #
  # So a client accessing the API can establish a tunneled connection from
  # their local machine to the API endpoint, which then becomes visible at 
  #   https://k8s-api.onp-k8s.admin.local-tunnels:PORT
  # where PORT is the port at which the local tunnel is running.
  - k8s-api.onp-k8s.admin.local-tunnels

# expose these components so that we can get metrics
# https://prometheus-operator.dev/docs/kube-prometheus-on-kubeadm/#kubeadm-pre-requisites
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
clusterName: "maron-cloud"

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
EOF

# Install Kubernetes without kube-proxy
kubeadm init --config "$HOME"/init_kubeadm.yaml --skip-phases=addon/kube-proxy --ignore-preflight-errors=NumCPU,Mem

mkdir -p "$HOME"/.kube
cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Install Helm CLI
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Cilium Helm chart
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${KUBE_API_SERVER_VIP} \
    --set k8sServicePort=8443

# Generate control plane certificate
KUBEADM_UPLOADED_CERTS=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)

# Set join configuration for other control plane nodes
cat > "$HOME"/join_kubeadm_cp.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
  kubeletExtraArgs:
    node-ip: "abcdefg"
discovery:
  bootstrapToken:
    apiServerEndpoint: "${KUBE_API_SERVER_VIP}:8443"
    token: "$KUBEADM_BOOTSTRAP_TOKEN"
    unsafeSkipCAVerification: true
controlPlane:
  certificateKey: "$KUBEADM_UPLOADED_CERTS"
  localAPIEndpoint:
    advertiseAddress: "abcdefg"
    bindPort: 6443
EOF

# Set join configuration for worker nodes
cat > "$HOME"/join_kubeadm_wk.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
  kubeletExtraArgs:
    node-ip: "abcdefg"
discovery:
  bootstrapToken:
    apiServerEndpoint: "${KUBE_API_SERVER_VIP}:8443"
    token: "$KUBEADM_BOOTSTRAP_TOKEN"
    unsafeSkipCAVerification: true
EOF
