#!/bin/bash
user=incredibuild
script_name=$0
PROJECT_DIR=$(pwd)
SSH_ROOT_DIR=/root/.ssh
WEB_DIR=/var/www/incredibuild
LOG=${script_name}.log

INCREDIBUILD_BINARY_FILES="\
    /bin/SlotStatistics \
    /bin/XgSubmit \
    /bin/GridServer \
    /bin/XgConsole \
    /bin/XgWait \
    /bin/XgRegisterMe \
    /bin/XgConnectMe \
    /bin/GridHelper \
    /usr/lib/libincredibuildintr.so"

INCREDIBUILD_SYSTEM_SCRIPTS="\
    /etc/default/incredibuild_profile.xml \
    /etc/init.d/incredibuild_virtualization.sh \
    /etc/init.d/incredibuild \
    /etc/init.d/incredibuild_helper \
    /etc/rsyslog.d/30-incredibuild.conf \
    /etc/rc1.d/S99incredibuild \
    /etc/rc2.d/S99incredibuild \
    /etc/rc3.d/S99incredibuild \
    /etc/rc4.d/S99incredibuild \
    /etc/rc5.d/S99incredibuild \
    /etc/rc6.d/S99incredibuild \
    /etc/rc1.d/S99incredibuild_helper \
    /etc/rc2.d/S99incredibuild_helper \
    /etc/rc3.d/S99incredibuild_helper \
    /etc/rc4.d/S99incredibuild_helper \
    /etc/rc5.d/S99incredibuild_helper \
    /etc/rc6.d/S99incredibuild_helper \
    /etc/default/incredibuild"

INCREDIBUILD_SERVICES=" \
    incredibuild \
    incredibuild_helper"

SSH_ADDONS="\
    $SSH_ROOT_DIR/incredibuild.pem \
    $SSH_ROOT_DIR/authorized_keys"

function check_conditions() {
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run sudo $script_name";
        exit
    fi
    rm $LOG
}

function stop_services() {
    echo "Stop incredibuild services:"
    for i in $INCREDIBUILD_SERVICES;
    do
        echo "stop service $i";
        service $i stop;
    done
}

function remove_web() {
    echo "Removing web gui:"
    if [ -d "$WEB_DIR/coordinator" ]; then
        rm -vfr $WEB_DIR/build_monitor                          1>>$LOG 2>&1;
    else
        rm -vfr $WEB_DIR                                        1>>$LOG 2>&1;
    fi
}

function remove_binaries() {
    echo "Removing binary files:"
    for i in $INCREDIBUILD_BINARY_FILES;
    do
        echo "removing $i";
        rm -vfr $i                                              1>>$LOG 2>&1;
    done
}

function remove_scripts() {
    echo "Removing script files:"
    for i in $INCREDIBUILD_SYSTEM_SCRIPTS;
    do
        echo "removing $i";
        rm -vfr $i                                              1>>$LOG 2>&1;
    done
    if ! [ -f /bin/GridCoordinator ]; then
        rm -vfr /etc/init.d/incredibuild_ssh_verification.sh    1>>$LOG 2>&1;
        rm -vfr /etc/init.d/clean_incredibuild_log.sh           1>>$LOG 2>&1;
    fi
}

function remove_ssh_addon() {
    echo "Removing ssh addon files:"
    if [[ -e /bin/GridCoordinator ]]; then
        echo "ssh is not removing, it shared with Coordinator"
    else
        for i in $SSH_ADDONS;
        do
            echo "removing $i";
            rm -vfr $i                                          1>>$LOG 2>&1;
        done
    fi
}

function remove_user() {
    if ! [ -f /bin/GridCoordinator ]; then
        echo "Removing user $user :"
        userdel $user                                           1>>$LOG 2>&1;
    fi
}

check_conditions
stop_services
remove_web
remove_binaries
remove_scripts
remove_ssh_addon
remove_user
echo "FINISHED"
