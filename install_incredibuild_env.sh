#!/bin/bash
password=xoreax
user=incredibuild
virtualization_script=/etc/init.d/incredibuild_virtualization.sh
tmp_virtualization_script=/tmp/virt.back
grid_domain_file=$1
script_name=$0

function check_conditions() {
    if [ -z "$grid_domain_file" ];
    then
        echo "Error, missing parameter";
        echo "please run $script_name grid_server_domain.conf";
        exit
    fi
}

function install_linux_packages() {
    sudo apt-get install -y \
        nfs-kernel-server cachefilesd
}

function enable_cachefs() {
    sudo sed "s;\# RUN;RUN;" -i /etc/default/cachefilesd
}

function setup_nfs() {
    found=$(grep "/ \*(" /etc/exports)
    if [ -z "$found" ];
    then
        sudo sh -c 'echo "/ *(rw,sync,no_subtree_check)" >> /etc/exports';
        sudo exportfs -ra;
    fi
}

function set_user_env() {
    sudo deluser $user
    echo "$password
$password





y
" | sudo adduser $user
    sudo adduser $user root
    sudo adduser $user sudo
    found=$(sudo grep "$user" /etc/sudoers)
    if [ -z "$found" ];
    then
        sudo sh -c "echo '%$user ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers";
    fi
}

function copy_system_files() {
    sudo sh -c "cp -fr etc/* /etc/"
    sudo sh -c "cp -fr bin/* /bin/"
    sudo sh -c "cp -fr $grid_domain_file /etc/grid_server_domain.conf"
}

function copy_web_files() {
    sudo sh -c "cp -fr web /home/$user"
}

check_conditions
install_linux_packages
setup_nfs
enable_cachefs
set_user_env
copy_system_files
copy_web_files

# end of script
echo "FINISHED"
exit
