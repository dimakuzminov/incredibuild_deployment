#!/bin/bash
PROJECT_DIR=$(pwd)
FILENAME=/etc/grid_server_domain.conf
USERNAME=root
SSH_ROOT_DIR=/root/.ssh
PERM_FILE=$PROJECT_DIR/linux.pem

function create_ssh_root() {
    sudo mkdir -p $SSH_ROOT_DIR
}

function create_config_file() {
    sudo sh -c "echo 'IdentityFile ~/.ssh/ids/%h/%r/id_rsa' > $SSH_ROOT_DIR/config"
    sudo sh -c "echo 'IdentityFile ~/.ssh/ids/%h/%r/id_dsa' >> $SSH_ROOT_DIR/config"
    sudo sh -c "echo 'IdentityFile ~/.ssh/ids/%h/id_rsa' >> $SSH_ROOT_DIR/config"
    sudo sh -c "echo 'IdentityFile ~/.ssh/ids/%h/id_dsa' >> $SSH_ROOT_DIR/config"
    sudo sh -c "echo 'IdentityFile ~/.ssh/id_rsa' >> $SSH_ROOT_DIR/config"
    sudo sh -c "echo 'IdentityFile ~/.ssh/id_dsa' >> $SSH_ROOT_DIR/config"
    sudo rm -f $SSH_ROOT_DIR/known_hosts
}

function create_domain_keys { 
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        sudo mkdir -p $SSH_ROOT_DIR/ids/$host
        sudo cp $PERM_FILE $SSH_ROOT_DIR/ids/$host/id_rsa 
        sudo chmod 0600 $SSH_ROOT_DIR/ids/$host/id_rsa
        sudo sh -c "ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/ids/$host/id_rsa.pub"  
    done
    sudo cp $PERM_FILE $SSH_ROOT_DIR/incredibuild.pem
}

create_ssh_root
create_config_file
create_domain_keys
