#!/bin/bash
password=xoreax
user=incredibuild
grid_domain_file=$1
script_name=$0
http_repository=/var/www/incredibuild
PROJECT_DIR=$(pwd)
DOMAN_SYSTEM_FILENAME=/etc/grid_server_domain.conf
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
        echo "please run sudo $script_name [optional:grid_server_domain.conf]";
        exit
    fi
}

function install_linux_packages() {
    echo -ne "Installing critical linux packages: .."
    apt-get update -qq
    apt-get install -qq -y libssh-dev ssh
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
    service incredibuild_coordinator stop
#    cp -fr etc/* /etc/
#    cp -fr bin/* /bin/
#    cp -fr usr/* /usr/
cp etc/init.d/incredibuild_coordinator          	/etc/init.d/
cp etc/init.d/incredibuild_ssh_verification.sh          /etc/init.d/
cp etc/rsyslog.d/30-incredibuild.conf			/etc/rsyslog.d/
cp bin/GridCoordinator  				/bin/
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc1.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc2.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc3.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc4.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc5.d/S98incredibuild_coordinator
    if [[ -f $grid_domain_file ]];
    then
        cp -fr $grid_domain_file $DOMAN_SYSTEM_FILENAME;
    else
        touch $DOMAN_SYSTEM_FILENAME;
    fi
}

function restart_services() {
    service rsyslog stop
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
    cat $DOMAN_SYSTEM_FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        mkdir -p $SSH_ROOT_DIR/ids/$host
        cp $PERM_FILE $SSH_ROOT_DIR/ids/$host/id_rsa
        chmod 0600 $SSH_ROOT_DIR/ids/$host/id_rsa
        ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/ids/$host/id_rsa.pub
    done
    cp $PERM_FILE $SSH_ROOT_DIR/incredibuild.pem
    chmod 0600 $PERM_FILE 
    mkdir -p $SSH_ROOT_DIR
    ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/authorized_keys
}

function start_services() {
    service rsyslog start
    service incredibuild_coordinator start
}

check_conditions
install_linux_packages &
__wait `jobs -p`
set_user_env
copy_system_files
restart_services
echo "Set security domain for grid Initiator machine"
create_ssh_root
create_config_file
create_domain_keys
start_services
# end of script
echo "FINISHED"
exit
