#!/bin/bash

VERB=${1:-"create"}
user_id=${2:-"101"}
password=${3:-"pa$$word"}

NODE_NAME=pve
ROLE="KVM-Console-Only"
vmid_pve=128
vmid_pbs=120

echo "${VERB} stand with userID=${user_id}"

[[ $VERB == "delete" ]] && {
    echo "$VERB stand.. "
    for i in {1..4}
        do
            pvesh create /nodes/${NODE_NAME}/qemu/${user_id}${i}/status/stop
            pvesh delete /nodes/${NODE_NAME}/qemu/${user_id}${i}
        done

    pvesh delete /nodes/${NODE_NAME}/network/vmbr1${user_id}
    pvesh set /nodes/${NODE_NAME}/network

    pvesh delete /access/users/user${user_id}@pve
    pvesh delete /pools/user${user_id}

    exit 0
}

[[ $VERB == "create" ]] && {
    pvesh create /pools/ --poolid user${user_id}

    pvesh create /access/users --userid user${user_id}@pve -password "${password}"
    pvesh set /access/acl --path /pool/user${user_id} --roles "KVM-Console-Only" --users user${user_id}@pve


    pvesh create /nodes/${NODE_NAME}/network --iface vmbr1${user_id} --type bridge --autostart true
    pvesh set /nodes/${NODE_NAME}/network

    for i in {1..3}
    do
        pvesh create /nodes/${NODE_NAME}/qemu/${vmid_pve}/clone --newid ${user_id}${i} --full false --name pve${i}-${user_id}
        pvesh set /nodes/pve-nsk/qemu/${user_id}${i}/config --net0 "model=virtio,bridge=vmbr100,tag=${user_id}" --net1 "model=virtio,bridge=vmbr1${user_id}" -protection false
    done

    pvesh create /nodes/${NODE_NAME}/qemu/${vmid_pbs}/clone --newid "${user_id}4" --full "false" --name "pbs1-${user_id}"
    pvesh set /nodes/pve-nsk/qemu/${user_id}4/config --net0 "model=virtio,bridge=vmbr100,tag=${user_id}" --net1 "model=virtio,bridge=vmbr1${user_id}" --protection false

    pvesh set /pools/user${user_id} --vms "${user_id}1,${user_id}2,${user_id}3,${user_id}4"
}
