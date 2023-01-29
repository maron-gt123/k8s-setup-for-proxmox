# script置き場
## k8sログ確認<br>
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
## キー渡し<br>
     # join_kubeadm_cp.yaml を seichi-onp-k8s-cp-2 と seichi-onp-k8s-cp-3 にコピー
     scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_cp.yaml seichi-onp-k8s-cp-2:~/
     scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_cp.yaml seichi-onp-k8s-cp-3:~/
     
     # seichi-onp-k8s-cp-2 と seichi-onp-k8s-cp-3 で kubeadm join
     ssh seichi-onp-k8s-cp-2 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
     ssh seichi-onp-k8s-cp-3 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
     
     # join_kubeadm_wk.yaml を seichi-onp-k8s-wk-1 と seichi-onp-k8s-wk-2 と seichi-onp-k8s-wk-3 にコピー
     scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml seichi-onp-k8s-wk-1:~/
     scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml seichi-onp-k8s-wk-2:~/
     scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml seichi-onp-k8s-wk-3:~/
     
     # seichi-onp-k8s-wk-1 と seichi-onp-k8s-wk-2 と seichi-onp-k8s-wk-3 で kubeadm join
     ssh seichi-onp-k8s-wk-1 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
     ssh seichi-onp-k8s-wk-2 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
     ssh seichi-onp-k8s-wk-3 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
