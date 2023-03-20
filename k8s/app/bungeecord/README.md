## bungeecordの導入<br>
* minecraftのproxyサーバにあたるbungeecordについてk8sでdeploymentをする


      sudo mkdir /k8s/bungeecord
      sudo chmod 700 /k8s/bungeecord
      cd /k8/bungeecord/
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/bungeecord/bungeecord-config.yaml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/bungeecord/bungeecord-deployment.yaml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/bungeecord/bungeecord-loadbalancer.yaml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/bungeecord/bungeecord-namespace.yaml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/bungeecord/nsf-pv-bungeecord.yaml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/bungeecord/nsf-pvc-bungeecord.yaml
      cd
      kubectl apply -f /k8s/bungeecord/bungeecord-namespace.yaml
      kubectl apply -f /k8s/bungeecord/.
