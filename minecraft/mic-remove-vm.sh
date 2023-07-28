#!/usr/bin/env bash

# region : set variables

TARGET_BRANCH=$1
TEMPLATE_VMID=9999
VMID_LOBBY=201
VMID_1=202
VMID_2=203
MARIA_DB=299
TARGETIP_1=192.168.1.141
TARGETIP_2=192.168.1.142
TARGETIP_3=192.168.1.143

# endregion


# region : delete mic-VM

# stop vm
ssh "${TARGETIP_1}" qm stop "${VMID_LOBBY}"
ssh "${TARGETIP_2}" qm stop "${VMID_1}"
ssh "${TARGETIP_3}" qm stop "${VMID_2}"
ssh "${TARGETIP_2}" qm stop "${MARIA_DB}"

# delete vm
## on onp-proxmox01-SV
ssh "${TARGETIP_1}" qm destroy "${VMID_LOBBY}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_1}" qm destroy "${TEMPLATE_VMID}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox02-SV
ssh "${TARGETIP_2}" qm destroy "${VMID_1}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_2}" qm destroy "${VMID_DB}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox03-SV
ssh "${TARGETIP_3}" qm destroy "${VMID_2}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s


# endregion
