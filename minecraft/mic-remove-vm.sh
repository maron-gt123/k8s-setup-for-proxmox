#!/usr/bin/env bash

# region : set variables

TARGET_BRANCH=$1
TEMPLATE_VMID=9999
vmid_lobby=201
vmid_1=202
vmid_2=203
targetip_1=192.168.1.50
targetip_2=192.168.1.51
targetip_3=192.168.1.52

# endregion


# region : delete mic-VM

# stop vm
ssh "${targetip_1}" qm stop "${vmid_lobby}"
ssh "${targetip_2}" qm stop "${vmid_1}"
ssh "${targetip_3}" qm stop "${vmid_2}"

# delete vm
## on onp-proxmox01-SV
ssh "${targetip_1}" qm destroy "${vmid_lobby}" --destroy-unreferenced-disks true --purge true
ssh "${targetip_1}" qm destroy "${TEMPLATE_VMID}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox02-SV
ssh "${targetip_2}" qm destroy "${vmid_1}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox03-SV
ssh "${targetip_3}" qm destroy "${vmid_2}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s


# endregion
