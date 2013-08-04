#!/bin/bash
password=xoreax
user=incredibuild
script_name=$0
coordinator_machine=$1
http_repository=/var/www/incredibuild
PROJECT_DIR=$(pwd)
SSH_ROOT_DIR=/root/.ssh
PERM_FILE=$PROJECT_DIR/linux.pem
MACHINE_ALREADY_REGISTERED="Received response from GridCoordinator, messageType \[ffffffff\] return code \[-1\]"
MACHINE_REGISTERED="Received response from GridCoordinator, messageType \[ffffffff\] return code \[0\]"
OS_DISTRIBUTION=$(lsb_release -is)
OS_RELEASE=$(lsb_release -rs)
OS_CODE=$(lsb_release -cs)
OS_VERSION=${OS_DISTRIBUTION}_${OS_RELEASE}_${OS_CODE}
PACKAGE_DIR=OS/$OS_VERSION
LOG=$script_name.log

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
    if ! [ -d "OS/$OS_VERSION" ];
    then
        echo "Error this OS [$OS_VERSION] is not Supported"
        exit
    fi
    rm $LOG
}

function print_log() {
    echo "######### $1"
    echo "######### $1" 1>>$LOG 2>&1
}

function print_version() {
    version_file=$PROJECT_DIR/OS/$OS_VERSION/version.txt 
    if [ -f "$version_file" ];
    then
        print_log "Processing: $script_name package version: $(cat $version_file) ....."
    else
        print_log "Processing: $script_name package version: this package cannot support $OS_VERSION"
    fi
}

function install_ubuntu_packages() {
    print_log "Enter ${FUNCNAME[0]}"
    echo -ne "[$OS_VERSION]: updating software list..."
    apt-get update 1>>$LOG 2>&1 &
    __wait `jobs -p`
    echo -ne "[$OS_VERSION]: install 3rd party packages..."
    apt-get install -y nfs-kernel-server cachefilesd libssh-dev boa ssh 1>>LOG 2>&1 &
    __wait `jobs -p`
    sed "s;\<Port 80\>;Port 8080;" -i /etc/boa/boa.conf
    print_log "Exit ${FUNCNAME[0]}"
}

function install_centos_packages() {
    print_log "Enter ${FUNCNAME[0]}"
    echo -ne "[$OS_VERSION]: updating software list..."
    yum  update -y 1>>$LOG 2>&1 &
    __wait `jobs -p`
    echo -ne "[$OS_VERSION]: install Apache..."
    yum install -y httpd  1>>$LOG 2>&1 &
    __wait `jobs -p`
    sed "s;\<Listen 80\>;Listen 8080;" -i /etc/httpd/conf/httpd.conf
    sed "s;/var/www/html;/var/www;" -i /etc/httpd/conf/httpd.conf
    service httpd stop                  1>>$LOG 2>&1 &
    service httpd start                 1>>$LOG 2>&1 &
    chkconfig httpd --add               1>>$LOG 2>&1 &
    chkconfig  httpd  on --level 235    1>>$LOG 2>&1 &
    echo -ne "[$OS_VERSION]: install cachefilesd..."
    yum install -y cachefilesd 1>>LOG 2>&1 &
    __wait `jobs -p`
    echo -ne "[$OS_VERSION]: install nfs kernel server..."
    yum install -y nfs-utils 1>>LOG 2>&1 &
    __wait `jobs -p`
    service nfs start                 1>>$LOG 2>&1 &
    chkconfig nfs --add               1>>$LOG 2>&1 &
    chkconfig  nfs  on --level 235    1>>$LOG 2>&1 &
    echo -ne "[$OS_VERSION]: download libssh 0.5.3 x86_64 rpm..."
    wget http://ftp5.gwdg.de/pub/opensuse/repositories/network:/synchronization:/files/CentOS_CentOS-6/x86_64/libssh-devel-0.5.3-14.1.x86_64.rpm 1>>$LOG 2>&1 &
    echo -ne "[$OS_VERSION]: installing libssh 0.5.3 x86_64 rpm..."
    yum install libssh-devel-0.5.3-14.1.x86_64.rpm 1>>$LOG 2>&1 &
    print_log "Exit ${FUNCNAME[0]}"
}

function enable_cachefs() {
    print_log "Enter ${FUNCNAME[0]}"
    sed "s;\# RUN;RUN;" -i /etc/default/cachefilesd
    print_log "Exit ${FUNCNAME[0]}"
}

function setup_nfs() {
    print_log "Enter ${FUNCNAME[0]}"
    found=$(grep "/ \*(" /etc/exports)
    if [ -z "$found" ];
    then
        sh -c 'echo "/ *(rw,sync,no_subtree_check)" >> /etc/exports';
        exportfs -ra;
    fi
    print_log "Exit ${FUNCNAME[0]}"
}

function set_user_env() {
    print_log "Enter ${FUNCNAME[0]}"
    if [ $(grep $user /etc/passwd) ];
    then
        print_log "user $user already exists, skipping";
    else
        echo "$password
$password





y
" | adduser $user 1>>$LOG 2>&1;
        adduser $user root 1>>$LOG 2>&1;
        adduser $user sudo 1>>$LOG 2>&1;
    fi
    found=$(grep "$user" /etc/sudoers)
    if [ -z "$found" ];
    then
        echo '%$user ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers;
    else
        print_log "user $user already sudo, skipping"
    fi
    print_log "Exit ${FUNCNAME[0]}"
}

function copy_system_files() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "stop incredibuild service..."
    service incredibuild stop 1>>$LOG 2>&1
    print_log "stop incredibuild_helper service..."
    service incredibuild_helper stop 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/default/incredibuild_profile.xml"         /etc/default/   -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/init.d/clean_incredibuild_log.sh"         /etc/init.d/    -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/init.d/incredibuild"                      /etc/init.d/    -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/init.d/incredibuild_helper"               /etc/init.d/    -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/init.d/incredibuild_ssh_verification.sh"  /etc/init.d/    -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/init.d/incredibuild_virtualization.sh"    /etc/init.d/    -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/etc/rsyslog.d/30-incredibuild.conf"           /etc/rsyslog.d/ -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/GridServer"                               /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/SlotStatistics"                           /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/TestCoordinator"                          /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/XgConsole"                                /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/XgRegisterMe"                             /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/XgConnectMe"                              /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/XgSubmit"                                 /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/bin/XgWait"                                   /bin/           -v 1>>$LOG 2>&1
    cp "$PACKAGE_DIR/usr/lib/libincredibuildintr.so"               /usr/lib/       -v 1>>$LOG 2>&1
    ln -sf /etc/init.d/incredibuild /etc/rc1.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc2.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc3.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc4.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc5.d/S99incredibuild
    ln -sf /etc/init.d/incredibuild /etc/rc1.d/S99incredibuild_helper
    ln -sf /etc/init.d/incredibuild /etc/rc2.d/S99incredibuild_helper
    ln -sf /etc/init.d/incredibuild /etc/rc3.d/S99incredibuild_helper
    ln -sf /etc/init.d/incredibuild /etc/rc4.d/S99incredibuild_helper
    ln -sf /etc/init.d/incredibuild /etc/rc5.d/S99incredibuild_helper
    print_log "Exit ${FUNCNAME[0]}"
}

function copy_web_files() {
    print_log "Enter ${FUNCNAME[0]}"
    mkdir -pv $http_repository/build_monitor                                            1>>$LOG 2>&1
    cp -vf "$PACKAGE_DIR/web/jquery.js"                  $http_repository/              1>>$LOG 2>&1
    cp -vf "$PACKAGE_DIR/web/processing.js"              $http_repository/              1>>$LOG 2>&1
    cp -vf "$PACKAGE_DIR/web/build_monitor/default.html" $http_repository/build_monitor 1>>$LOG 2>&1
    print_log "Exit ${FUNCNAME[0]}"
}

function restart_3rd_side_services() {
    print_log "Enter ${FUNCNAME[0]}"
    service rsyslog stop 1>>$LOG 2>&1
    service boa stop     1>>$LOG 2>&1
    print_log "Exit ${FUNCNAME[0]}"
}

function prepare_ssh() {
    print_log "Enter ${FUNCNAME[0]}"
    mkdir -p $SSH_ROOT_DIR
    rm -f $SSH_ROOT_DIR/known_hosts
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_rsa' > $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_dsa' >> $SSH_ROOT_DIR/config
    chmod 0600 $PERM_FILE
    cp $PERM_FILE $SSH_ROOT_DIR/incredibuild.pem -v 1>>$LOG 2>&1
    chmod 0600 $PERM_FILE 
    ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/authorized_keys
    print_log "Exit ${FUNCNAME[0]}"
}

function register_machine() {
    print_log "Enter ${FUNCNAME[0]}"
    XgRegisterMe -h $coordinator_machine > temp_log
    status_already_registered=$(grep "$MACHINE_ALREADY_REGISTERED" temp_log)
    status_registered=$(grep "$MACHINE_REGISTERED" temp_log)
    if ! [[ -z "$status_already_registered" ]];
    then
        print_log "local machine is already registered"
    else
        if ! [[ -z "$status_registered" ]];
        then
            print_log "local machine is registered"
        else
            print_log "!!! Error cannot acccess correctly coordinator machine $coordinator_machine"
            print_log "!!! Uninstall process..."
            remove_web
            remove_user
            remove_system_files
            exit 1
        fi
    fi
    cat << EOF > /etc/default/incredibuild
coordinator = $coordinator_machine
EOF
    print_log "Exit ${FUNCNAME[0]}"
}

function start_services() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "start 3rd side part services..."
    service rsyslog start
    service boa start
    print_log "start incredibuild service..."
    service incredibuild start
    print_log "start incredibuild service..."
    service incredibuild_helper start
    print_log "Exit ${FUNCNAME[0]}"
}

function remove_user() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "Removing user $user :"
    userdel $user 1>>$LOG 2>&1
    print_log "Exit ${FUNCNAME[0]}"
}

function remove_web() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "Removing web gui:"
    if [ -d "$http_repository/coordinator" ]; then
        rm -vfr $http_repository/build_monitor 1>>$LOG 2>&1;
    else
        rm -vfr $http_repository  1>>$LOG 2>&1;
    fi
    print_log "Exit ${FUNCNAME[0]}"
}

function remove_system_files() {
    print_log "Enter ${FUNCNAME[0]}"
    rm /etc/rc1.d/S99incredibuild                       1>>$LOG 2>&1
    rm /etc/rc2.d/S99incredibuild                       1>>$LOG 2>&1
    rm /etc/rc3.d/S99incredibuild                       1>>$LOG 2>&1
    rm /etc/rc4.d/S99incredibuild                       1>>$LOG 2>&1
    rm /etc/rc5.d/S99incredibuild                       1>>$LOG 2>&1
    rm /etc/rc6.d/S99incredibuild                       1>>$LOG 2>&1
    rm /etc/rc1.d/S99incredibuild_helper                1>>$LOG 2>&1
    rm /etc/rc2.d/S99incredibuild_helper                1>>$LOG 2>&1
    rm /etc/rc3.d/S99incredibuild_helper                1>>$LOG 2>&1
    rm /etc/rc4.d/S99incredibuild_helper                1>>$LOG 2>&1
    rm /etc/rc5.d/S99incredibuild_helper                1>>$LOG 2>&1
    rm /etc/rc6.d/S99incredibuild_helper                1>>$LOG 2>&1
    rm /etc/default/incredibuild_profile.xml            1>>$LOG 2>&1
    rm /etc/init.d/clean_incredibuild_log.sh            1>>$LOG 2>&1
    rm /etc/init.d/incredibuild                         1>>$LOG 2>&1
    rm /etc/init.d/incredibuild_helper                  1>>$LOG 2>&1
    rm /etc/init.d/incredibuild_ssh_verification.sh     1>>$LOG 2>&1
    rm /etc/init.d/incredibuild_virtualization.sh       1>>$LOG 2>&1
    rm /etc/rsyslog.d/30-incredibuild.conf              1>>$LOG 2>&1
    rm /bin/GridServer                                  1>>$LOG 2>&1
    rm /bin/SlotStatistics                              1>>$LOG 2>&1
    rm /bin/TestCoordinator                             1>>$LOG 2>&1
    rm /bin/XgConsole                                   1>>$LOG 2>&1
    rm /bin/XgRegisterMe                                1>>$LOG 2>&1
    rm /bin/XgConnectMe                                 1>>$LOG 2>&1
    rm /bin/XgSubmit                                    1>>$LOG 2>&1
    rm /bin/XgWait                                      1>>$LOG 2>&1
    rm /usr/lib/libincredibuildintr.so                  1>>$LOG 2>&1
    print_log "Exit ${FUNCNAME[0]}"
}

function prepare_ubuntu_package() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "configuring machine..."
    install_ubuntu_packages
    setup_nfs
    enable_cachefs
    set_user_env
    copy_system_files
    copy_web_files
    restart_3rd_side_services
    print_log "configuring incredibuild..."
    prepare_ssh
    register_machine
    start_services
    print_log "Exit ${FUNCNAME[0]}"
}

function prepare_centos_package() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "configuring machine..."
    install_centos_packages
    setup_nfs
    enable_cachefs
    set_user_env
    copy_system_files
    copy_web_files
    restart_3rd_side_services
    print_log "configuring incredibuild..."
    prepare_ssh
    register_machine
    start_services
    print_log "Exit ${FUNCNAME[0]}"
}

#############################################################################
# __main__:
#                                   - script entry point
#                                   - check current Linux version and 
#                                   - launch prepare process
#                                   - Curently supported:
#                                           Ubuntu 12.04
#############################################################################
function __main__() {
    check_conditions
    print_version
    if ! [ $(expr match "$OS_VERSION" "Ubuntu") == "0" ]; then
        prepare_ubuntu_package
        exit
    fi
    if ! [ $(expr match "$OS_VERSION" "CentOS") == "0" ]; then
        prepare_centos_package
        exit
    fi
    echo "We shouldn't be here, script is not update to support OS [$OS_VERSION]"
}

#############################################################################
#############################################################################
# Code execution point:
#                           - __main__ enter point for script execution                      
#
#############################################################################
#############################################################################

__main__
