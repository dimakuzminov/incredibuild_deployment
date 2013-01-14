#!/bin/bash
NEW_NAME=$1

function test_arg_conditions() {
    if [[ -z $NEW_NAME ]];
    then
        echo "please use $0 [newhostname]";
        exit -1;
    fi
}

function set_new_hostname() {
    oldname=$(grep "127.0.0.1" /etc/hosts | awk '{print $2;}')
    sudo sed "s;$oldname;$NEW_NAME;" -i /etc/hosts
    sudo sh -c "echo $NEW_NAME > /etc/hostname"
    sudo hostname -F /etc/hostname
    echo "Need to reboot machine ...."
    sudo reboot
}

test_arg_conditions
set_new_hostname
