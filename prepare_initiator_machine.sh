#!/bin/bash
password=xoreax
user=incredibuild
virtualization_script=/etc/init.d/incredibuild_virtualization.sh
tmp_virtualization_script=/tmp/virt.back
grid_domain_file=$1
script_name=$0
http_repository=/var/www/incredibuild
PROJECT_DIR=$(pwd)
FILENAME=/etc/grid_server_domain.conf
USERNAME=root
SSH_ROOT_DIR=/root/.ssh
PERM_FILE=$PROJECT_DIR/linux.pem

function check_conditions() {
    if [ -z "$grid_domain_file" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name grid_server_domain.conf";
        exit
    fi
}

function install_linux_packages() {
    sudo apt-get update
    sudo apt-get install -y \
        nfs-kernel-server cachefilesd libssh-dev boa ssh
    sudo sed "s;\<Port 80\>;Port 8080;" -i /etc/boa/boa.conf
}

function enable_cachefs() {
    sudo sed "s;\# RUN;RUN;" -i /etc/default/cachefilesd
}

function setup_nfs() {
    found=$(grep "/ \*(" /etc/exports)
    if [ -z "$found" ];
    then
        sudo sh -c 'echo "/ *(rw,sync,no_subtree_check)" >> /etc/exports';
        sudo exportfs -ra;
    fi
}

function set_user_env() {
    sudo deluser $user
    echo "$password
$password





y
" | sudo adduser $user
    sudo adduser $user root
    sudo adduser $user sudo
    found=$(sudo grep "$user" /etc/sudoers)
    if [ -z "$found" ];
    then
        sudo sh -c "echo '%$user ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers";
    fi
}

function copy_system_files() {
    sudo sh -c "cp -fr etc/* /etc/"
    sudo sh -c "cp -fr bin/* /bin/"
    sudo sh -c "cp -fr $grid_domain_file /etc/grid_server_domain.conf"
}

function copy_web_files() {
    sudo mkdir -p $http_repository 
    sudo sh -c "cp -fr web/* $http_repository/"
}

function restart_services() {
    sudo service rsyslog stop
    sudo service rsyslog start
    sudo service boa stop
    sudo service boa start
}

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
    sudo chmod 0600 $PERM_FILE 
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

check_conditions
install_linux_packages
setup_nfs
enable_cachefs
set_user_env
copy_system_files
copy_web_files
restart_services

echo "Set security domain for grid Initiator machine"
create_ssh_root
create_config_file
create_domain_keys

# end of script
echo "FINISHED"
exit