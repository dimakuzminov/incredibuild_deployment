#!/bin/bash
password=xoreax
user=incredibuild
script_name=$0
PROJECT_DIR=$(pwd)
SSH_ROOT_DIR=/root/.ssh
PERM_FILE=$PROJECT_DIR/linux.pem

function __wait() {
    while [ -e /proc/$1 ]
    do
        echo -ne "."
        sleep 1;
    done
    echo -ne " done"
    echo ""
}

function check_conditions() {
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run sudo $script_name";
        exit
    fi
}

function install_linux_packages() {
    echo -ne "Installing critical linux packages: .."
    apt-get update -qq
    apt-get install -qq -y \
        nfs-kernel-server cachefilesd libssh-dev boa ssh
    sed "s;\<Port 80\>;Port 8080;" -i /etc/boa/boa.conf
}

function enable_cachefs() {
    sed "s;\# RUN;RUN;" -i /etc/default/cachefilesd
}

function setup_nfs() {
    found=$(grep "/ \*(" /etc/exports)
    if [ -z "$found" ];
    then
        echo "/ *(rw,sync,no_subtree_check)" >> /etc/exports;
        exportfs -ra;
    fi
}

function set_user_env() {
    if [ $(grep $user /etc/passwd) ];
    then
        echo "user $user already exists, skipping";
    else
        echo "$password
$password





y
" | adduser $user;
        adduser $user root;
        adduser $user sudo;
    fi
    found=$(grep "$user" /etc/sudoers)
    if [ -z "$found" ];
    then
        echo '%$user ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers;
    else
        echo "user $user already sudo, skipping"
    fi
}

function copy_system_files() {
    cp -fr etc/* /etc/
}

function create_ssh_root() {
    mkdir -p $SSH_ROOT_DIR
}

function create_config_file() {
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_rsa' > $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_dsa' >> $SSH_ROOT_DIR/config
}

function create_domain_keys { 
    chmod 0600 $PERM_FILE 
    mkdir -p $SSH_ROOT_DIR
    ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/authorized_keys
}

check_conditions
install_linux_packages &
__wait `jobs -p`
setup_nfs
enable_cachefs
set_user_env
copy_system_files

echo "Set security system for BuildMachine"
create_ssh_root
create_config_file
create_domain_keys

# end of script
echo "FINISHED"
exit
