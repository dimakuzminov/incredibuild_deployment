#!/bin/bash
PROJECT_DIR=$(pwd)
FILENAME=$1
HOSTNAMELOCALDNS=""

function check_conditions() {
    if [ -z "$FILENAME" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name [ grid_server_domain.conf ]";
        exit
    fi
}

function clean_environment() {
    rm -fr icecc_prepare.sh 
    rm -fr icecc_prepare_init.sh 
    rm -fr JOBS3
    rm -fr temp.icecc_install.*
}

function __wait() {
    while [ -e /proc/$1 ]
    do 
        sleep 0.1; 
    done
}

function generate_hostname_local_dns() {
    HOSTNAMELOCALDNS=`dnsdomainname -A | tr -d ' '`
    if [ -z "$HOSTNAMELOCALDNS" ];
    then
        echo "failed to extract internal dns";
    else
        echo "extracted internal dns[$HOSTNAMELOCALDNS]";
    fi
}

function install_icecc_package() {
    LOG_FILE=temp.icecc_install.$1
    echo "Preparing icecc machine $1 ..."
    sudo scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null $2 $1:./ > $LOG_FILE 2>&1
    echo "yes
    "| sudo ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null $1 ./$2 >> $LOG_FILE 2>&1
    echo "Finish preparing icecc machine $1"
}

function install_icecc_machines() {
    cat << EOF > icecc_prepare.sh
#!/bin/bash
dpkg --configure -a
apt-get update -qq
apt-get install -qq -y icecc icecc++ icecc-monitor
sed "s;ICECC_SCHEDULER_HOST=\".*\";ICECC_SCHEDULER_HOST=\"$HOSTNAMELOCALDNS\";" -i /etc/icecc/icecc.conf
/etc/init.d/icecc stop
sleep 1
/etc/init.d/icecc start
EOF
    cat << EOF > icecc_prepare_init.sh
#!/bin/bash
dpkg --configure -a
apt-get update -qq
apt-get install -qq -y icecc icecc++ icecc-monitor
sed "s;START_ICECC_SCHEDULER=\"false\";START_ICECC_SCHEDULER=\"true\";" -i /etc/default/icecc
/etc/init.d/icecc stop
sleep 1
/etc/init.d/icecc start
EOF
    chmod 777 icecc_prepare.sh
    chmod 777 icecc_prepare_init.sh
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        if [ "$host" == "$HOSTNAMELOCALDNS" ];
        then
            install_icecc_package $host icecc_prepare_init.sh &
        else
            install_icecc_package $host icecc_prepare.sh &
        fi
        echo `jobs -p` > JOBS3
    done
    JOBS=`cat JOBS3`
    for s in $JOBS
    do
        __wait $s
    done
}

check_conditions
clean_environment
generate_hostname_local_dns
install_icecc_machines
