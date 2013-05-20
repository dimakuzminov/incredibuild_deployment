#!/bin/bash
password=xoreax
user=incredibuild
grid_domain_file=$1
script_name=$0
http_repository=/var/www/incredibuild
PROJECT_DIR=$(pwd)
FILENAME=/etc/grid_server_domain.conf
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
    if [ -z "$grid_domain_file" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name grid_server_domain.conf";
        exit
    fi
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run sudo $script_name grid_server_domain.conf";
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
        sh -c 'echo "/ *(rw,sync,no_subtree_check)" >> /etc/exports';
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
    service incredibuild stop
    cp -fr etc/* /etc/
    cp -fr bin/* /bin/
    cp -fr usr/* /usr/
    cp -fr $grid_domain_file /etc/grid_server_domain.conf
    service incredibuild start
}

function copy_web_files() {
    mkdir -p $http_repository
    cp -fr web/* $http_repository/
}

function restart_services() {
    service rsyslog stop
    sleep 1
    service rsyslog start
    service boa stop
    sleep 1
    service boa start
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
    rm -f $SSH_ROOT_DIR/known_hosts
}

function create_domain_keys { 
    chmod 0600 $PERM_FILE
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        mkdir -p $SSH_ROOT_DIR/ids/$host
        cp $PERM_FILE $SSH_ROOT_DIR/ids/$host/id_rsa
        chmod 0600 $SSH_ROOT_DIR/ids/$host/id_rsa
        ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/ids/$host/id_rsa.pub
    done
    cp $PERM_FILE $SSH_ROOT_DIR/incredibuild.pem
}

check_conditions
install_linux_packages &
__wait `jobs -p`
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
