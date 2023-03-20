##  k8s dashboardの導入
* k8sのcluster操作ダッシュボードの導入を実施

      sudo mkdir /k8s/dashboard/
      sudo chmod 700 /k8s/dashboard/
      cd /k8/dashboard/
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/dashboard/dashboard_account.yml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/dashboard/dashboard_rolebinding.yml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/dashboard/dashboard_svc.yml
      wget https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main/k8s/app/dashboard/recommended.yaml
      cd
      
