#!/bin/bash
password=xoreax
user=incredibuild
virtualization_script=/etc/init.d/incredibuild_virtualization.sh
tmp_virtualization_script=/tmp/virt.back

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
}

install_linux_packages
setup_nfs
enable_cachefs
set_user_env
copy_system_files

# end of script
echo "FINISHED"
exit
