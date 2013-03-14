#!/bin/bash
PROJECT_DIR=$(pwd)
FILENAME=$1
HOSTNAME=$2
PERM_FILE=$PROJECT_DIR/linux.pem
HOSTNAMELOCALDNS=""

function check_conditions() {
    if [ -z "$FILENAME" || -z "$HOSTNAME" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name [ amazon.tag file ] [ one of public dns that will be host]";
        exit
    fi
}

function generate_hostname_local_dns() {
    HOSTNAMELOCALDNS=`echo "yes
    "| ssh -oStrictHostKeyChecking=no -i ./linux.pem ubuntu@$HOSTNAME dnsdomainname -A`
    if [ -z "$HOSTNAMELOCALDNS" ];
    then
        echo "failed to extract internal dns from public dns[$HOSTNAME]";
    else
        echo "extracted internal dns[$HOSTNAMELOCALDNS] from public dns[$HOSTNAME]";
    fi
}

function install_icecc_package() {
    echo "prepare icecc machine $1"
    scp -i ./linux.pem $2 ubuntu@$1:./
    scp -i ./linux.pem env_icecc.sh ubuntu@$1:./
    echo "yes
    "| ssh -i ./linux.pem ubuntu@$1 ./$2
}

function install_icecc_machines() {
    rm -fr icecc_prepare.sh 
    cat << EOF > icecc_prepare.sh
#!/bin/bash
sudo apt-get update
sudo apt-get install -y icecc icecc++ icecc-monitor
sudo sed "s;ICECC_SCHEDULER_HOST==\"\";ICECC_SCHEDULER_HOST=\"$HOSTNAMELOCALDNS\";" -i /etc/icecc/icecc.conf
EOF
    cat << EOF > icecc_prepare_init.sh
#!/bin/bash
sudo apt-get update
sudo apt-get install -y icecc icecc++ icecc-monitor
sudo sed "s;START_ICECC_SCHEDULER=\"false\";START_ICECC_SCHEDULER=\"true\";" -i /etc/default/icecc
EOF
    chmod 777 icecc_prepare.sh
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $2;}')
        if [ "$host" == "$HOSTNAME" ];
        then
            install_icecc_package $host icecc_prepare_init.sh
        else
            install_icecc_package $host icecc_prepare.sh
        fi
    done
}

check_conditions
generate_hostname_local_dns
install_icecc_machines
