#!/bin/bash
MACHINE_NAME=$1
USERNAME=$2
PASSWORD=$3
MOUNT_POINTS=$4
MACHINE_NAME_ROOT=/tmp/$MACHINE_NAME
CACHE_FS_OPTION="-o fsc,rw,soft,intr,rsize=32768,wsize=32768,noatime"

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
        if [ -z "$MOUNT_POINTS" ];
        then
            echo "Connecting to $MACHINE_NAME,  No mount points";
            mount $MACHINE_NAME:/ $MACHINE_NAME_ROOT/ $CACHE_FS_OPTION;
        else
            echo "Connecting to $MACHINE_NAME,  Found mount points";
            for i in $MOUNT_POINTS;
            do
                mount $MACHINE_NAME:/$i $MACHINE_NAME_ROOT/$i $CACHE_FS_OPTION;
            done
        fi
    else
        echo "$MACHINE_NAME is already connected";
    fi
}

function verify_remote() {
    result=$(mount | grep $MACHINE_NAME)
    if [ -z "$result" ];
    then
        echo "Critical error $MACHINE_NAME is not connected, aborting";
        exit -1
    fi
}

function prepare_virtualization() {
    result=$(ls $MACHINE_NAME_ROOT/dev)
    if [ -z "$result" ];
    then
        echo "setup dev for $MACHINE_NAME";
        mount -o bind /dev $MACHINE_NAME_ROOT/dev;
    else
        echo "$MACHINE_NAME dev was ready";
    fi
    result=$(ls $MACHINE_NAME_ROOT/proc)
    if [ -z "$result" ];
    then
        echo "setup proc for $MACHINE_NAME";
        mount -t proc none $MACHINE_NAME_ROOT/proc;
    else
        echo "$MACHINE_NAME proc was ready";
    fi
}

create_root
connect_remote
verify_remote
prepare_virtualization
