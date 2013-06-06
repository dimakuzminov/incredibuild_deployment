#!/bin/bash
PROJECT_DIR=$(pwd)
FILENAME=$1
PERM_FILE=$PROJECT_DIR/linux.pem
SCRIPT=/etc/init.d/incredibuild_virtualization.sh

function check_conditions() {
    if [ -z "$FILENAME" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name [ machine.list file ]";
        exit
    fi
    if [ -z "$PROJECT_DIR/./$SCRIPT" ];
    then
        echo "Cannot find script $PROJECT_DIR/./$SCRIPT";
        exit
    fi
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run sudo $script_name [optional:grid_server_domain.conf]";
        exit
    fi
}

function clean_environment() {
    rm -fr temp.virtualization_update.log.* 
}

function wait_ping_dead() {
    ping -c 1 $1 1>>$2 2>&1
    while [ $? == 0 ]
    do
        echo -ne "." 1>>$2 2>&1
        sleep 1;
        ping -c 1 $1 1>>$2 2>&1
    done
}

function wait_ping_alive() {
    ping -c 1 $1 1>>$2 2>&1
    while ! [ $? == 0 ]
    do
        echo -ne "." 1>>$2 2>&1
        sleep 1;
        ping -c 1 $1 1>>$2 2>&1
    done
}

function update_machine() {
    echo -ne "[$1 STARTED]"
    LOG_FILE=temp.virtualization_update.log.$1
    echo "Updating..." > $LOG_FILE
    echo "yes
    "| scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./linux.pem $PROJECT_DIR/./$SCRIPT $1:$SCRIPT 1>>$LOG_FILE 2>&1
    echo "yes
    "| ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./linux.pem $1 sh -c "sync;reboot" 1>>$LOG_FILE 2>&1
    echo "reboot machine and wait.." 1>>$LOG_FILE 2>&1
    wait_ping_dead $1 $LOG_FILE
    wait_ping_alive $1 $LOG_FILE
    echo "finshed updating" 1>>$LOG_FILE 2>&1
    echo -ne "[$1 DONE]"
}

function __wait() {
    while [ -e /proc/$1 ]
    do 
        echo -ne "."
        sleep 1; 
    done
}

function launch_update() { 
    echo "Updating machines:...."
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        update_machine $host &
        echo `jobs -p` > JOBS
    done
    JOBS=`cat JOBS`
    for s in $JOBS
    do
        __wait $s
    done
    echo ". done"
    echo "Update finished"
}

check_conditions
clean_environment
launch_update
