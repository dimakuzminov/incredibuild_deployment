#!/bin/bash
PROJECT_DIR=$(pwd)
FILENAME=$1
PERM_FILE=$PROJECT_DIR/linux.pem
HOSTNAMELOCALDNS=""

function check_conditions() {
    if [ -z "$FILENAME" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name [ grid_server_domain.conf ]";
        exit
    fi
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

function install_package() {
    echo "prepare icecc machine $1"
    sudo scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null $2 $1:./
    sudo scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null $3 $1:./
    echo "yes
    "| sudo ssh -oStrictHostKeyChecking=no  -oUserKnownHostsFile=/dev/null $1 ./$2
}

function install_machines() {
    rm -fr grid_update.sh 
    rm -fr incredibuild_deployment.tar.bz2
    tar cjf incredibuild_deployment.tar.bz2 etc $FILENAME prepare_*
    cat << EOF > grid_update.sh
#!/bin/bash

function umount_list() {
    file=\$1
    cat \$file | while read LINE
    do
        mnt=\$(echo \$LINE | awk '{print \$3;}')
        umount \$mnt
    done
}

#umount current
mount | grep -w proc | grep -w tmp > tmp_mounted_proc.list
mount | grep -w nfs | grep -w tmp > tmp_mounted_init_machines.list
umount_list tmp_mounted_proc.list
umount_list tmp_mounted_init_machines.list

#update system
pushd incredibuild_deployment
tar xf ../incredibuild_deployment.tar.bz2
./prepare_helper_machine.sh $FILENAME
popd
EOF
    chmod 777 grid_update.sh
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $1;}')
        if [ "$host" == "$HOSTNAMELOCALDNS" ];
        then
            echo "the machine $host is local machine"
            ./prepare_initiator_machine.sh $FILENAME
        else
            echo "the machine $host is remote machine"
            install_package $host grid_update.sh incredibuild_deployment.tar.bz2
        fi
    done
}

check_conditions
generate_hostname_local_dns
install_machines
