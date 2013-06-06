#!/bin/bash
password=xoreax
user=incredibuild
script_name=$0
coordinator_machine=$1
http_repository=/var/www/incredibuild
PROJECT_DIR=$(pwd)
SSH_ROOT_DIR=/root/.ssh
PERM_FILE=$PROJECT_DIR/linux.pem
version=$(cat version.txt)
MACHINE_ALREADY_REGISTERED="Received response from GridCoordinator, messageType \[ffffffff\] return code \[-1\]"
MACHINE_REGISTERED="Received response from GridCoordinator, messageType \[ffffffff\] return code \[0\]"

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
    if [[ -z $coordinator_machine ]];
    then
        echo "Error, must specify coordinator_machine as DNS or IP address";
        echo "please run sudo $script_name [coordinator_machine_name]";
        exit
    fi
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run sudo $script_name [coordinaor_machine_name]";
        exit
    fi
}

function print_version() {
    echo "###############################################################################################"
    echo "Processing: $script_name package version: $version ....."
    echo "###############################################################################################"
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
    ln -sf /etc/init.d/incredibuild /etc/rc1.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc2.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc3.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc4.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc5.d/S99incredibuild
}

function copy_web_files() {
    mkdir -p $http_repository
    cp -fr web/* $http_repository/
}

function restart_services() {
    service rsyslog stop
    service boa stop
}

function prepare_ssh() {
    mkdir -p $SSH_ROOT_DIR
    rm -f $SSH_ROOT_DIR/known_hosts
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_rsa' > $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_dsa' >> $SSH_ROOT_DIR/config
    chmod 0600 $PERM_FILE
    cp $PERM_FILE $SSH_ROOT_DIR/incredibuild.pem
    chmod 0600 $PERM_FILE 
    ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/authorized_keys
}

function register_machine() {
    XgRegisterMe -h $coordinator_machine > temp_log
    status_already_registered=$(grep "$MACHINE_ALREADY_REGISTERED" temp_log)
    status_registered=$(grep "$MACHINE_REGISTERED" temp_log)
    if ! [[ -z "$status_already_registered" ]];
    then
        echo "local machine is already registered"
    else
        if ! [[ -z "$status_registered" ]];
        then
            echo "local machine is registered"
        else
            echo "!!! Error cannot acccess corectly coordinator machine $coordinator_machine"
        fi
    fi
    cat << EOF > /etc/default/incredibuild
coordinator = $coordinator_machine
EOF
}

function start_services() {
    service rsyslog start
    service boa start
    service incredibuild start
}

check_conditions
print_version
install_linux_packages &
__wait `jobs -p`
setup_nfs
enable_cachefs
set_user_env
copy_system_files
copy_web_files
restart_services
echo "Set security domain for grid Initiator machine"
prepare_ssh
register_machine
start_services
# end of script
echo "FINISHED"
exit
