#!/usr/bin/env bash

#region set variables

TARGET_BRANCH=$1
CLOUDINIT_IMAGE=noble-server-cloudimg-amd64.img
CLOUDINIT_IMAGE_URL=https://cloud-images.ubuntu.com/noble/current/${CLOUDINIT_IMAGE}
TEMPLATE_VMID=9999
CLOUDINIT_IMAGE_TARGET_VOLUME=iSCSI-network-01-lun01
TEMPLATE_BOOT_IMAGE_TARGET_VOLUME=iSCSI-network-01-lun01
BOOT_IMAGE_TARGET_VOLUME=iSCSI-network-01-lun01
SNIPPET_TARGET_VOLUME=prox-NFS
SNIPPET_TARGET_PATH=/mnt/pve/${SNIPPET_TARGET_VOLUME}/snippets
REPOSITORY_RAW_SOURCE_URL="https://raw.githubusercontent.com/maron-gt123/k8s-setup-for-proxmox/main"

VM_LIST=(
    # ---
    # vmid:       proxmox上でVMを識別するID
    # vmname:     proxmox上でVMを識別する名称およびホスト名
    # cpu:        VMに割り当てるコア数(vCPU)
    # mem:        VMに割り当てるメモリ(MB)
    # vmsrvip:    VMのService Segment側NICに割り振る固定IP
    # targetip:   VMの配置先となるProxmoxホストのIP
    # targethost: VMの配置先となるProxmoxホストのホスト名
    # ---
    #vmid   #vmname  #cpu  #mem     #vmsrvip     #targetip    #targethost
    "201 mic-lobby-SV 4    4096  192.168.15.87 192.168.1.141 onp-prox01-SV"
    "202 mic-paper-01 4    4096  192.168.15.88 192.168.1.142 onp-prox02-SV"
    "203 mic-paper-02 4    4096  192.168.15.89 192.168.1.143 onp-prox03-SV"
)
#endregion

# ---

#region create-template

# download the cloudinit image
wget $CLOUDINIT_IMAGE_URL
# create a new VM and attach Network Adaptor
# vmbr15=service Network Segment (192.168.15.0/24)
qm create $TEMPLATE_VMID --cores 2 --memory 4096 --net0 virtio,bridge=vmbr15 --name minecraftSV-template
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
#endregion

# region create vm from template
for array in "${VM_LIST[@]}"
do
    echo "${array}" | while read -r vmid vmname cpu mem vmsrvip targetip targethost
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
  # run install scripts
  - su - cloudinit -c "curl -s ${REPOSITORY_RAW_SOURCE_URL}/minecraft/minecraft-setup.sh > ~/minecraft-setup.sh"
  - su - cloudinit -c "chmod 700 ~/minecraft-setup.sh"
  - su - cloudinit -c "sudo apt install -y prometheus prometheus-node-exporter"
  - su - cloudinit -c "sudo apt install -y openjdk-21-jre"
  - su - cloudinit -c "sudo apt install -y zip"
  - su - cloudinit -c "sudo apt install -y git"
  - su - cloudinit -c "sudo apt install -y linux-modules-extra-$(uname -r)"
  - su - cloudinit -c "sudo bash ~/minecraft-setup.sh"
  # change default shell to bash
  - chsh -s $(which bash) cloudinit
EOF

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
