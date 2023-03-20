# region : create update.sh

sudo mkdir /k8s
sudo chmod 777 /k8s

mkdir /k8s/metallb
sudo chmod 770 /k8s/metallb
  
cat > /k8s/metallb/ipaddresspool.yaml <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.15.60-192.168.15.80
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF

cd /k8s/metallb
sudo curl -O https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
cd

kubectl apply -f /k8s/metallb/metallb-native.yaml
sleep 10
kubectl apply -f /k8s/metallb/ipaddresspool.yaml
