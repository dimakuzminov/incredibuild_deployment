#!/bin/bash
user=incredibuild
script_name=$0
PROJECT_DIR=$(pwd)
WEB_DIR=/var/www/incredibuild
LOG=${script_name}.log

INCREDIBUILD_COORDINATOR_BINARY_FILES="\
    /bin/GridCoordinator"

INCREDIBUILD_COORDINATOR_SYSTEM_SCRIPTS="\
    /etc/init.d/incredibuild_coordinator \
	/etc/grid_server_domain.conf \
    /etc/rc1.d/S98incredibuild_coordinator \
    /etc/rc2.d/S98incredibuild_coordinator \
    /etc/rc3.d/S98incredibuild_coordinator \
    /etc/rc4.d/S98incredibuild_coordinator \
    /etc/rc5.d/S98incredibuild_coordinator \
    /etc/rc6.d/S98incredibuild_coordinator"


INCREDIBUILD_COORDINATOR_SERVICES=" \
    incredibuild_coordinator"

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
    for i in $INCREDIBUILD_COORDINATOR_SERVICES;
    do
        echo "stop service $i";
        service $i stop;
    done
}

function remove_binaries() {
    echo "Removing binary files:"
    for i in $INCREDIBUILD_COORDINATOR_BINARY_FILES;
    do
        echo "removing $i";
        rm -vfr $i                      1>>$LOG 2>&1;
    done
}

function remove_web() {
    echo "Removing web gui:"
    if [ -d "$WEB_DIR/build_monitor" ]; then
        rm -vfr $WEB_DIR/coordinator    1>>$LOG 2>&1;
    else
        rm -vfr $WEB_DIR                1>>$LOG 2>&1;
    fi
}

function remove_scripts() {
    echo "Removing script files:"
    for i in $INCREDIBUILD_COORDINATOR_SYSTEM_SCRIPTS;
    do
        echo "removing $i";
        rm -vfr $i                      1>>$LOG 2>&1;
    done
    if ! [ -f /bin/GridServer ]; then
        rm -vfr /etc/init.d/clean_incredibuild_log.sh           1>>$LOG 2>&1;
    fi
}

check_conditions
stop_services
remove_web
remove_binaries
remove_scripts
echo "FINISHED"
