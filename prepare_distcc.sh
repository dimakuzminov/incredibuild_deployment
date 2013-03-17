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
    rm -fr distcc_prepare.sh 
    rm -fr distcc_prepare_init.sh 
    rm -fr JOBS4
    rm -fr HOSTS
    rm -fr temp.distcc_install.*
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

function install_distcc_package() {
    LOG_FILE=temp.distcc_install.$1
    echo "Preparing distcc machine $1 ..."
    sudo scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null $2 $1:./ > $LOG_FILE 2>&1
    echo "yes
    "| sudo ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null $1 ./$2 >> $LOG_FILE 2>&1
    echo "Finish preparing distcc machine $1"
}

function install_distcc_machines() {
    hosts=""
    cat $FILENAME | while read LINE
    do
        hosts="$(echo $LINE | awk '{print $1;}') $hosts"
        echo $hosts > HOSTS
    done
    hosts=`cat HOSTS`
    cat << EOF > distcc_prepare.sh
#!/bin/bash
dpkg --configure -a
apt-get update -qq
apt-get install -qq -y distcc
echo "$hosts" > /etc/distcc/hosts
sed "s;LISTENER=\".*\";LISTENER=\"\";" -i /etc/default/distcc
sed "s;ALLOWEDNETS=\".*\";ALLOWEDNETS=\"127.0.0.1 10.0.0.0/8 192.168.0.0/16\";" -i /etc/default/distcc
sed "s;ZEROCONF=\".*\";ZEROCONF=\"true\";" -i /etc/default/distcc
sed "s;STARTDISTCC=\".*\";STARTDISTCC=\"true\";" -i /etc/default/distcc
/etc/init.d/distcc stop
sleep 1
/etc/init.d/distcc start
EOF
    cat << EOF > distcc_prepare_init.sh
#!/bin/bash
dpkg --configure -a
apt-get update -qq
apt-get install -qq -y distcc
echo "$hosts" > /etc/distcc/hosts
sed "s;LISTENER=\".*\";LISTENER=\"\";" -i /etc/default/distcc
sed "s;ALLOWEDNETS=\".*\";ALLOWEDNETS=\"127.0.0.1 10.0.0.0/8 192.168.0.0/16\";" -i /etc/default/distcc
sed "s;ZEROCONF=\".*\";ZEROCONF=\"true\";" -i /etc/default/distcc
sed "s;STARTDISTCC=\".*\";STARTDISTCC=\"true\";" -i /etc/default/distcc
/etc/init.d/distcc stop
sleep 1
/etc/init.d/distcc start
EOF
    chmod 777 distcc_prepare.sh
    chmod 777 distcc_prepare_init.sh
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        if [ "$host" == "$HOSTNAMELOCALDNS" ];
        then
            install_distcc_package $host distcc_prepare_init.sh &
        else
            install_distcc_package $host distcc_prepare.sh &
        fi
        echo `jobs -p` > JOBS4
    done
    JOBS=`cat JOBS4`
    for s in $JOBS
    do
        __wait $s
    done
}

check_conditions
clean_environment
generate_hostname_local_dns
install_distcc_machines
