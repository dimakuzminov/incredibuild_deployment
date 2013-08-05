#!/bin/bash
NEW_NAME=$1
AVAHI_PACKAGE="avahi-compat-howl.x86_64 \
avahi-compat-libdns_sd.x86_64 \
avahi-dnsconfd.x86_64 \
avahi-tools.x86_64 \
avahi-ui-tools.x86_64"

function test_arg_conditions() {
    if ! [ $(id -u) = 0 ];
    then
        echo "Error, must be run in root mode";
        echo "please run: sudo $0 [newhostname]";
        exit
    fi
    if [[ -z $NEW_NAME ]];
    then
        echo "Error, missing hostname parameter";
        echo "please run: sudo $0 [newhostname]";
        exit
    fi
}

function check_avahi_package() {
    if ! [[ -f /etc/init.d/avahi-daemon ]];
    then
        yum install -y $AVAHI_PACKAGE;
        rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms;
        rpm -ivh http://dl.atrpms.net/all/atrpms-repo-6-6.el6.x86_64.rpm;
        cd /etc/yum.repos.d;
        sed -i 's/enabled=0/enabled=1/g' atrpms.repo;
        yum --enablerepo=atrpms install -y nss-mdns;
    fi
}

function set_new_hostname() {
    oldname=$(grep "127.0.0.1" /etc/hosts | awk '{print $2;}')
    sudo sed "s;$oldname;$NEW_NAME;" -i /etc/hosts
    sudo sed "s;$oldname;$NEW_NAME;" -i /etc/sysconfig/network
    sudo sh -c "echo $NEW_NAME > /etc/hostname"
    sudo hostname -F /etc/hostname
    echo "Need to reboot machine ...."
    sudo reboot
}

test_arg_conditions
check_avahi_package
set_new_hostname
