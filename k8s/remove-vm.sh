#!/usr/bin/env bash

# region : set variables

TARGET_BRANCH=$1
TEMPLATE_VMID=8888
CP01=801
CP02=802
CP03=803
WK01=881
WK02=882
WK03=883
TARGETIP_1=192.168.1.50
TARGETIP_2=192.168.1.51
TARGETIP_3=192.168.1.52

# endregion


# region : delete mic-VM

# stop vm
ssh "${TARGETIP_1}" qm stop "${CP01}"
ssh "${TARGETIP_2}" qm stop "${CP02}"
ssh "${TARGETIP_3}" qm stop "${CP03}"
ssh "${TARGETIP_1}" qm stop "${WK01}"
ssh "${TARGETIP_2}" qm stop "${WK02}"
ssh "${TARGETIP_3}" qm stop "${WK03}"

# delete vm
## on onp-proxmox01-SV
ssh "${TARGETIP_1}" qm destroy "${CP01}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_1}" qm destroy "${WK01}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_1}" qm destroy "${TEMPLATE_VMID}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox02-SV
ssh "${TARGETIP_2}" qm destroy "${CP02}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_2}" qm destroy "${WK02}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox03-SV
ssh "${TARGETIP_3}" qm destroy "${CP03}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_3}" qm destroy "${WK03}" --destroy-unreferenced-disks true --purge true

## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s


# endregion
