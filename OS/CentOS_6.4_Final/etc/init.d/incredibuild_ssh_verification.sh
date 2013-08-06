#!/bin/bash
script_name=$0
host_name=$1
SSH_ROOT_DIR=/root/.ssh
PERM_FILE=$SSH_ROOT_DIR/incredibuild.pem

function check_conditions() {
    if [ -z "$host_name" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name [machine_name:dns,ip]";
        exit -1
    fi
}

function verify_machine_ssh_config { 
    if ! [[ -f $SSH_ROOT_DIR/ids/$host_name/id_rsa.pub ]];
    then
        sudo mkdir -p $SSH_ROOT_DIR/ids/$host_name;
        sudo cp $PERM_FILE $SSH_ROOT_DIR/ids/$host_name/id_rsa; 
        sudo chmod 0600 $SSH_ROOT_DIR/ids/$host_name/id_rsa;
        sudo sh -c "ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/ids/$host_name/id_rsa.pub";
        restorecon -R -v /root/.ssh;
    fi
}

check_conditions
verify_machine_ssh_config
echo "FINISHED"
exit
