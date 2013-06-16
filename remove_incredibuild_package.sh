#!/bin/bash
user=incredibuild
script_name=$0
PROJECT_DIR=$(pwd)
SSH_ROOT_DIR=/root/.ssh
WEB_DIR=/var/www/incredibuild

INCREDIBUILD_BINARY_FILES="\
    /bin/SlotStatistics \
    /bin/XgSubmit \
    /bin/GridServer \
    /bin/XgConsole \
    /bin/XgWait \
    /bin/XgRegisterMe \
    /usr/lib/libincredibuildintr.so"

INCREDIBUILD_SYSTEM_SCRIPTS="\
    /etc/default/incredibuild_profile.xml \
    /etc/init.d/incredibuild_ssh_verification.sh \
    /etc/init.d/clean_incredibuild_log.sh \
    /etc/init.d/incredibuild_virtualization.sh \
    /etc/init.d/incredibuild \
    /etc/rsyslog.d/30-incredibuild.conf \
    /etc/rc5.d/S99incredibuild \
    /etc/default/incredibuild"

INCREDIBUILD_SERVICES=" \
    incredibuild"

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
    rm -vfr $WEB_DIR
}

function remove_binaries() {
    echo "Removing binary files:"
    for i in $INCREDIBUILD_BINARY_FILES;
    do
        echo "removing $i";
        rm -vfr $i;
    done
}

function remove_scripts() {
    echo "Removing script files:"
    for i in $INCREDIBUILD_SYSTEM_SCRIPTS;
    do
        echo "removing $i";
        rm -vfr $i;
    done
}

function remove_ssh_addon() {
    echo "Removing ssh addon files:"
    for i in $SSH_ADDONS;
    do
        echo "removing $i";
        rm -vfr $i;
    done
}

function remove_user() {
    echo "Removing user $user :"
    userdel $user
}

check_conditions
stop_services
remove_web
remove_binaries
remove_scripts
remove_ssh_addon
remove_user
echo "FINISHED"
