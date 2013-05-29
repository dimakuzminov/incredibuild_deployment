#!/bin/bash
PROJECT_DIR=$(pwd)
FILENAME=$1
PERM_FILE=$PROJECT_DIR/linux.pem

function check_conditions() {
    if [ -z "$FILENAME" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name [ amazon.tag file ]";
        exit
    fi
}

function clean_environment() {
    rm -fr essential_prepare.sh 
    rm -fr grid_server_domain.conf.$FILENAME
    rm -fr temp.amazon.internaldns.*
    rm -fr temp.amazon.log.*
    rm -fr JOBS
    rm -fr JOBS2
}

function write_grid_domain_file() {
    LOG_FILE=temp.amazon.log.$1
    echo "Exctracting internal DNS from $1 ..."
    echo "Extracting internal DNS..." > $LOG_FILE
    PUBLICDNS=$1
    DNS=`echo "yes
    "| ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./linux.pem ubuntu@$PUBLICDNS dnsdomainname -A 2>>$LOG_FILE`
    if [ -z "$DNS" ];
    then
        echo "failed to extract internal dns from public dns[$PUBLICDNS]" >> $LOG_FILE;
    else
        echo "extracted internal dns[$DNS] from public dns[$PUBLICDNS]" >> $LOG_FILE;
        echo "$DNS 1" > temp.amazon.internaldns.$1;
    fi
    echo "Finish exctracting internal DNS from $1"
}

function __wait() {
    while [ -e /proc/$1 ]
    do 
        sleep 0.1; 
    done
}

function create_domain_keys() { 
    sudo chmod 0600 $PERM_FILE 
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $2;}')
        write_grid_domain_file $host &
        echo `jobs -p` > JOBS
    done
    JOBS=`cat JOBS`
    for s in $JOBS
    do
        __wait $s
    done
    for i in `ls temp.amazon.internaldns.*`
    do
        cat $i >> grid_server_domain.conf.$FILENAME;
    done
}

function install_helper_package() {
    LOG_FILE=temp.amazon.log.$1
    echo "prepare helper machine $1"
    scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./linux.pem grid_server_domain.conf.$FILENAME ubuntu@$1:./ >> $LOG_FILE 2>&1 
    scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./linux.pem essential_prepare.sh ubuntu@$1:./ >> $LOG_FILE 2>&1
    echo "yes
    "| ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./linux.pem ubuntu@$1 ./essential_prepare.sh >> $LOG_FILE 2>&1
    echo "FINISH machine $1"
}

function install_helper_machines() {
    cat << EOF > essential_prepare.sh
#!/bin/bash
sudo apt-get update -qq
sudo apt-get install -qq -y git
git clone http://github.com/dimakuzminov/incredibuild_deployment
pushd incredibuild_deployment
git pull
mv ../grid_server_domain.conf.$FILENAME .
./prepare_helper_machine.sh grid_server_domain.conf.$FILENAME
popd
EOF
    chmod 777 essential_prepare.sh
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $2;}')
        install_helper_package $host &
        echo `jobs -p` > JOBS2
    done
    JOBS=`cat JOBS2`
    for s in $JOBS
    do
        __wait $s
    done
}

check_conditions
clean_environment
create_domain_keys
install_helper_machines
