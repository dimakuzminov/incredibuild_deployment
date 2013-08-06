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
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run sudo $script_name [optional:grid_server_domain.conf]";
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
    apt-get update -y 1>>$LOG 2>&1 &
    __wait `jobs -p`
    echo -ne "[$OS_VERSION]: install 3rd party packages..."
    apt-get install -y libssh-dev ssh 1>>$LOG 2>&1 &
    __wait `jobs -p`
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
    service httpd stop                  1>>$LOG 2>&1
    service httpd start                 1>>$LOG 2>&1
    chkconfig httpd --add               1>>$LOG 2>&1
    chkconfig  httpd  on --level 235    1>>$LOG 2>&1
    ssh_file=libssh-0.5.0-1.el6.rf.x86_64.rpm
    ssh_devel_file=libssh-devel-0.5.0-1.el6.rf.x86_64.rpm
    if ! [ -f $ssh_file ]
    then 
      echo -ne "[$OS_VERSION]: download $ssh_file ..."
      wget http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/$ssh_file 1>>$LOG 2>&1 &
      __wait `jobs -p`
      echo -ne "[$OS_VERSION]: installing $ssh_file ..."
      yum install libssh-0.5.0-1.el6.rf.x86_64.rpm 1>>$LOG 2>&1 &
      __wait `jobs -p`
    fi
    if ! [ -f $ssh_devel_file ]
    then 
      echo -ne "[$OS_VERSION]: download $ssh_devel_file ..."
      wget http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/$ssh_devel_file 1>>$LOG 2>&1 & 
      __wait `jobs -p`
      echo -ne "[$OS_VERSION]: installing $ssh_devel_file ..."
      yum install libssh-devel-0.5.0-1.el6.rf.x86_64.rpm 1>>$LOG 2>&1 &
      __wait `jobs -p`
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
    print_log "stop incredibuild_coordinator service..."
    service incredibuild_coordinator stop
    cp -v "$PACKAGE_DIR/etc/init.d/incredibuild_coordinator"          /etc/init.d/      1>>$LOG 2>&1
    cp -v "$PACKAGE_DIR/etc/init.d/incredibuild_ssh_verification.sh"  /etc/init.d/      1>>$LOG 2>&1
    cp -v "$PACKAGE_DIR/etc/rsyslog.d/30-incredibuild.conf"           /etc/rsyslog.d/   1>>$LOG 2>&1
    cp -v "$PACKAGE_DIR/bin/GridCoordinator"                          /bin/             1>>$LOG 2>&1
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc1.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc2.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc3.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc4.d/S98incredibuild_coordinator
    ln -sf /etc/init.d/incredibuild_coordinator /etc/rc5.d/S98incredibuild_coordinator
    if [[ -f $grid_domain_file ]];
    then
        cp -fvr $grid_domain_file $DOMAN_SYSTEM_FILENAME 1>>$LOG 2>&1; 
    else
        touch $DOMAN_SYSTEM_FILENAME;
    fi
    print_log "Exit ${FUNCNAME[0]}"
}

function copy_web_files() {
    print_log "Enter ${FUNCNAME[0]}"
    mkdir -pv $http_repository/coordinator                                              1>>$LOG 2>&1
    cp -vf "$PACKAGE_DIR/web/jquery.js"                  $http_repository/              1>>$LOG 2>&1
    cp -vf "$PACKAGE_DIR/web/processing.js"              $http_repository/              1>>$LOG 2>&1
    cp -vf "$PACKAGE_DIR/web/coordinator/default.html"   $http_repository/coordinator   1>>$LOG 2>&1
    print_log "Exit ${FUNCNAME[0]}"
}

function stop_3rd_side_services() {
    print_log "Enter ${FUNCNAME[0]}"
    service rsyslog stop
    print_log "Exit ${FUNCNAME[0]}"
}

function create_ssh_root() {
    print_log "Enter ${FUNCNAME[0]}"
    mkdir -pv $SSH_ROOT_DIR  1>>$LOG 2>&1
    print_log "Exit ${FUNCNAME[0]}"
}

function create_config_file() {
    print_log "Enter ${FUNCNAME[0]}"
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_rsa' > $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/%r/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/ids/%h/id_dsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_rsa' >> $SSH_ROOT_DIR/config
    echo 'IdentityFile ~/.ssh/id_dsa' >> $SSH_ROOT_DIR/config
    rm -vf $SSH_ROOT_DIR/known_hosts    1>>$LOG 2>&1
    print_log "Enter ${FUNCNAME[0]}"
}

function create_domain_keys { 
    print_log "Enter ${FUNCNAME[0]}"
    chmod 0600 $PERM_FILE
    cat $DOMAN_SYSTEM_FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        mkdir -pv $SSH_ROOT_DIR/ids/$host                                   1>>$LOG 2>&1
        cp -v $PERM_FILE $SSH_ROOT_DIR/ids/$host/id_rsa                     1>>$LOG 2>&1
        chmod 0600 $SSH_ROOT_DIR/ids/$host/id_rsa
        ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/ids/$host/id_rsa.pub
    done
    cp -v $PERM_FILE $SSH_ROOT_DIR/incredibuild.pem                         1>>$LOG 2>&1
    chmod 0600 $PERM_FILE 
    mkdir -p $SSH_ROOT_DIR                                                  1>>$LOG 2>&1
    ssh-keygen -y -f $PERM_FILE > $SSH_ROOT_DIR/authorized_keys
    print_log "Exit ${FUNCNAME[0]}"
}

function start_services() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "start 3rd side part services..."
    service rsyslog start
    print_log "start incredibuild_coordinator service..."
    service incredibuild_coordinator start
    print_log "Exit ${FUNCNAME[0]}"
}

function prepare_ubuntu_package() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "configuring machine..."
    install_ubuntu_packages
    set_user_env
    copy_system_files
    copy_web_files
    stop_3rd_side_services
    print_log "configuring incredibuild..."
    create_ssh_root
    create_config_file
    create_domain_keys
    start_services
}

function prepare_centos_package() {
    print_log "Enter ${FUNCNAME[0]}"
    print_log "configuring machine..."
    install_centos_packages
    set_user_env
    copy_system_files
    copy_web_files
    stop_3rd_side_services
    print_log "configuring incredibuild..."
    create_ssh_root
    create_config_file
    create_domain_keys
    start_services
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
