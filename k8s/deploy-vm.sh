#!/usr/bin/env bash

#region set variables

TARGET_BRANCH=$1
CLOUDINIT_IMAGE=noble-server-cloudimg-amd64.img
CLOUDINIT_IMAGE_URL=https://cloud-images.ubuntu.com/noble/current/${CLOUDINIT_IMAGE}
TEMPLATE_VMID=8888
CLOUDINIT_IMAGE_TARGET_VOLUME=iSCSI-network-01-lun01
TEMPLATE_BOOT_IMAGE_TARGET_VOLUME=iSCSI-network-01-lun01
BOOT_IMAGE_TARGET_VOLUME=local-lvm
SNIPPET_TARGET_VOLUME=prox-NFS
SNIPPET_TARGET_PATH=/mnt/pve/${SNIPPET_TARGET_VOLUME}/snippets
REPOSITORY_RAW_SOURCE_URL="https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/${TARGET_BRANCH}"

VM_LIST=(
    # ---
    # vmid:       proxmox上でVMを識別するID
    # vmname:     proxmox上でVMを識別する名称およびホスト名
    # cpu:        VMに割り当てるコア数(vCPU)
    # mem:        VMに割り当てるメモリ(MB)
    # vmsrvip:    VMのService Segment側NICに割り振る固定IP
    # vmsanip:    VMのStorage Segment側NICに割り振る固定IP
    # targetip:   VMの配置先となるProxmoxホストのIP
    # targethost: VMの配置先となるProxmoxホストのホスト名
    # ---
    #vmid #vmname      #cpu #mem  #vmsrvip    #vmsanip     #targetip    #targethost
    "801 onp-k8s-cp-1 4    9216  192.168.15.81 192.168.6.81 192.168.6.141 onp-prox01-SV"
    "802 onp-k8s-cp-2 4    9216  192.168.15.82 192.168.6.82 192.168.6.142 onp-prox02-SV"
    "803 onp-k8s-cp-3 4    9216  192.168.15.83 192.168.6.83 192.168.6.143 onp-prox03-SV"
    "881 onp-k8s-wk-1 6    26624 192.168.15.84 192.168.6.84 192.168.6.141 onp-prox01-SV"
    "882 onp-k8s-wk-2 6    26624 192.168.15.85 192.168.6.85 192.168.6.142 onp-prox02-SV"
    "883 onp-k8s-wk-3 6    26624 192.168.15.86 192.168.6.86 192.168.6.143 onp-prox03-SV"
)
#endregion

# ---

#region create-template

# download the cloudinit image
wget $CLOUDINIT_IMAGE_URL
# create a new VM and attach Network Adaptor
# vmbr15=service Network Segment (192.168.15.0/24)
# vmbr6=Storage Network Segment (192.168.6.0/24)
qm create $TEMPLATE_VMID --cores 2 --memory 4096 --net0 virtio,bridge=vmbr15 --net1 virtio,bridge=vmbr06 --name onp-k8s-template
# import the downloaded disk to $TEMPLATE_BOOT_IMAGE_TARGET_VOLUME storage
qm importdisk $TEMPLATE_VMID $CLOUDINIT_IMAGE $TEMPLATE_BOOT_IMAGE_TARGET_VOLUME
# finally attach the new disk to the VM as scsi drive
qm set $TEMPLATE_VMID --scsihw virtio-scsi-pci --scsi0 $TEMPLATE_BOOT_IMAGE_TARGET_VOLUME:vm-$TEMPLATE_VMID-disk-0
# add Cloud-Init CD-ROM drive
qm set $TEMPLATE_VMID --ide2 $CLOUDINIT_IMAGE_TARGET_VOLUME:cloudinit
# set the bootdisk parameter to scsi0
qm set $TEMPLATE_VMID --boot c --bootdisk scsi0
# set serial console
qm set $TEMPLATE_VMID --serial0 socket --vga serial0
# migrate to template
qm template $TEMPLATE_VMID
# cleanup
rm $CLOUDINIT_IMAGE

# region create vm from template
for array in "${VM_LIST[@]}"
do
    echo "${array}" | while read -r vmid vmname cpu mem vmsrvip vmsanip targetip targethost
    do
        # clone from template
        # in clone phase, can't create vm-disk to local volume
        qm clone "${TEMPLATE_VMID}" "${vmid}" --name "${vmname}" --full true --target "${targethost}"
        
        # set compute resources
        ssh -n "${targetip}" qm set "${vmid}" --cores "${cpu}" --memory "${mem}"

        # move vm-disk to local
        ssh -n "${targetip}" qm move-disk "${vmid}" scsi0 "${BOOT_IMAGE_TARGET_VOLUME}" --delete true

        # resize disk (Resize after cloning, because it takes time to clone a large disk)
        ssh -n "${targetip}" qm resize "${vmid}" scsi0 30G

        # create snippet for cloud-init(user-config)
        # START irregular indent because heredoc
# ----- #
cat > "$SNIPPET_TARGET_PATH"/"$vmname"-user.yaml << EOF
#cloud-config
hostname: ${vmname}
timezone: Asia/Tokyo
manage_etc_hosts: true
chpasswd:
  expire: False
users:
  - default
  - name: cloudinit
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    # mkpasswd --method=SHA-512 --rounds=4096
    # password is zaq12wsx
    passwd: \$6\$rounds=4096\$Xlyxul70asLm\$9tKm.0po4ZE7vgqc.grptZzUU9906z/.vjwcqz/WYVtTwc5i2DWfjVpXb8HBtoVfvSY61rvrs/iwHxREKl3f20
ssh_pwauth: false
ssh_authorized_keys: []
package_upgrade: true
runcmd:
  # set ssh_authorized_keys
  - su - cloudinit -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  - su - cloudinit -c "curl -sS https://github.com/maron-gt123.keys >> ~/.ssh/authorized_keys"
  - su - cloudinit -c "chmod 600 ~/.ssh/authorized_keys"
  # set nfs & iscsi client
  - su - cloudinit -c "sudo apt-get install -y nfs-common"
  - su - cloudinit -c "sudo apt-get install -y open-iscsi"
  - su - cloudinit -c "sudo systemctl enable --now iscsid"
  # run install scripts
  - su - cloudinit -c "curl -s ${REPOSITORY_RAW_SOURCE_URL}/k8s/k8s-node-setup.sh > ~/k8s-node-setup.sh"
  - su - cloudinit -c "sudo bash ~/k8s-node-setup.sh ${vmname} ${TARGET_BRANCH}"
  # change default shell to bash
  - chsh -s $(which bash) cloudinit
EOF


# ----- #
        # END irregular indent because heredoc

        # only seichi-onp-k8s-cp-1, append snippet for cloud-init(user-config)
        if [ "${vmname}" = "onp-k8s-cp-1" ]
        then
            # START irregular indent because heredoc
# --------- #
cat >> "$SNIPPET_TARGET_PATH"/"$vmname"-user.yaml << EOF
  # add kubeconfig to cloudinit user
  - su - cloudinit -c "mkdir -p ~/.kube"
  - su - cloudinit -c "sudo cp /etc/kubernetes/admin.conf ~/.kube/config"
  - su - cloudinit -c "sudo chown cloudinit:cloudinit ~/.kube/config"
  # copy kubeadm-join-config to cloudinit user home directory
  - su - cloudinit -c "sudo cp /root/join_kubeadm_cp.yaml ~/join_kubeadm_cp.yaml"
  - su - cloudinit -c "sudo cp /root/join_kubeadm_wk.yaml ~/join_kubeadm_wk.yaml"
EOF
# --------- #
            # END irregular indent because heredoc
        fi


# ----- #
        # END irregular indent because heredoc

        # create snippet for cloud-init(network-config)
        # START irregular indent because heredoc
# ----- #
cat > "$SNIPPET_TARGET_PATH"/"$vmname"-network.yaml << EOF
version: 1
config:
  - type: physical
    name: ens18
    subnets:
    - type: static
      address: '${vmsrvip}'
      netmask: '255.255.255.0'
      gateway: '192.168.15.1'
  - type: physical
    name: ens19
    subnets:
    - type: static
      address: '${vmsanip}'
      netmask: '255.255.255.0'
  - type: nameserver
    address:
    - '192.168.10.132'
    search:
    - 'local'
EOF
        # set snippet to vm
        ssh -n "${targetip}" qm set "${vmid}" --cicustom "user=${SNIPPET_TARGET_VOLUME}:snippets/${vmname}-user.yaml,network=${SNIPPET_TARGET_VOLUME}:snippets/${vmname}-network.yaml"

        # start vm
        ssh -n "${targetip}" qm start "${vmid}"

    done
done

# endregion
