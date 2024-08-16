#!/usr/bin/env bash

# region : set variables
TARGET_BRANCH=$1
TEMPLATE_VMID=9999
VM_LIST=(
    #vmid   #vmname  #cpu  #mem #targetip
    "201 mic-paper-01 4    4096 192.168.1.143"
    "202 mic-paper-02 4    4096 192.168.1.143"
)
# endregion

for array in "${VM_LIST[@]}"
do
    echo "${array}" | while read -r vmid vmname cpu mem targetip
    do
        # stop vm
        ssh "${targetip}" qm stop "${vmid}"
        # delete vm
        ssh "${targetip}" qm destroy "${vmid}" --destroy-unreferenced-disks true --purge true
        ## wait due to prevent to cluster-data mismatch on proxmox
        sleep 20s
