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

function write_grid_domain_file() {
    DNS=`echo "yes
    "| ssh -oStrictHostKeyChecking=no -i ./linux.pem ubuntu@$1 dnsdomainname -A`
    if [ -z "$DNS" ];
    then
        echo "failed to extract internal dns from public dns[$1]";
    else
        echo "extracted internal dns[$DNS] from public dns[$1]";
        echo "$DNS 2" >> grid_server_domain.conf.$FILENAME;
    fi
}

function create_domain_keys() { 
    rm -fr grid_server_domain.conf.$FILENAME
    sudo chmod 0600 $PERM_FILE 
    cat $FILENAME | while read LINE
    do
        host=$(echo $LINE | awk '{print $2;}')
        write_grid_domain_file $host
    done
}

function install_helper_package() {
    echo "prepare helper machine $1"
    scp -i ./linux.pem grid_server_domain.conf.$FILENAME ubuntu@$1:./
    scp -i ./linux.pem essential_prepare.sh ubuntu@$1:./
    echo "yes
    "| ssh -i ./linux.pem ubuntu@$1 ./essential_prepare.sh
}

function install_helper_machines() {
    rm -fr essential_prepare.sh 
    cat << EOF > essential_prepare.sh
#!/bin/bash
sudo apt-get update
sudo apt-get install -y git
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
        install_helper_package $host
    done
}

check_conditions
create_domain_keys
install_helper_machines
