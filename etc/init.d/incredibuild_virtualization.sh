#!/bin/bash
MACHINE_NAME=$1
USERNAME=$2
PASSWORD=$3
MACHINE_NAME_ROOT=/tmp/$MACHINE_NAME
CACHE_FS_OPTION="-o fsc,rw,soft,intr,rsize=32768,wsize=32768,udp,noatime"

function create_root() {
    if [[ -d $MACHINE_NAME_ROOT ]];
    then
        echo "Directory $MACHINE_NAME_ROOT exists";
    else
        echo "Creating directory $MACHINE_NAME_ROOT";
        mkdir $MACHINE_NAME_ROOT;
    fi
}

function connect_remote() {
    result=$(mount | grep $MACHINE_NAME)
    if [ -z "$result" ];
    then
        echo "Connecting to $MACHINE_NAME";
        echo $PASSWORD | sudo -S mount $MACHINE_NAME:/ $MACHINE_NAME_ROOT $CACHE_FS_OPTION;
    else
        echo "$MACHINE_NAME is already connected";
    fi
}

function prepare_virtualization() {
    result=$(ls $MACHINE_NAME_ROOT/dev)
    if [ -z "$result" ];
    then
        echo "setup dev for $MACHINE_NAME";
        echo $PASSWORD | sudo -S mount -o bind /dev $MACHINE_NAME_ROOT/dev;
    else
        echo "$MACHINE_NAME dev was ready";
    fi
    result=$(ls $MACHINE_NAME_ROOT/proc)
    if [ -z "$result" ];
    then
        echo "setup proc for $MACHINE_NAME";
        echo $PASSWORD | sudo -S mount -t proc none $MACHINE_NAME_ROOT/proc;
    else
        echo "$MACHINE_NAME proc was ready";
    fi
}

create_root
connect_remote
prepare_virtualization
