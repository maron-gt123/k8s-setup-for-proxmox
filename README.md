# script置き場




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
