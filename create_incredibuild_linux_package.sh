#!/bin/bash
OS_DISTRIBUTION=$(lsb_release -is)
OS_RELEASE=$(lsb_release -rs)
OS_CODE=$(lsb_release -cs)
OS_VERSION=${OS_DISTRIBUTION}_${OS_RELEASE}_${OS_CODE}

function create_package_name(){
git describe --all --exact-match `git rev-parse HEAD` > tmpfile
current=$(cat tmpfile)
echo "Current tag or revision is [$current]"
if [[ "$current" == *tags* ]]
then
    echo "It's tag";
    suffix=${current:5}
else
    echo "It's revision";
    suffix=dirty_revision
fi
echo "suffix is[$suffix]"
eval "$1=incredibuild_linux_$suffix.tar.bz2"
}

package_name=''
create_package_name package_name
echo "package_name is [$package_name]"
if ! [ $(expr match "$OS_VERSION" "Ubuntu") == "0" ]; then
    tar cjf $package_name prepare_coordinator_machine.sh prepare_incredibuild_machine.sh remove_coordinator_package.sh remove_incredibuild_package.sh OS/Ubuntu_12.04_precise/web/
    exit
fi
if ! [ $(expr match "$OS_VERSION" "CentOS") == "0" ]; then
    tar cjf $package_name prepare_coordinator_machine.sh prepare_incredibuild_machine.sh remove_coordinator_package.sh remove_incredibuild_package.sh OS/CentOS_6.4_Final/web/
    exit
fi
echo "We shouldn't be here, script is not update to support OS [$OS_VERSION]"
