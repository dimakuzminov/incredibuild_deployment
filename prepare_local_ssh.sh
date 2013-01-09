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
}

function create_domain_keys { 
    sudo mkdir -p $SSH_ROOT_DIR
    sudo cp $PERM_FILE $SSH_ROOT_DIR/id_rsa 
    sudo sh -c "ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/id_rsa.pub"  
}

create_ssh_root
create_config_file
create_domain_keys
