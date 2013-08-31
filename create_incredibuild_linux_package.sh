#!/bin/bash

PACKAGE_ITEMS_LIST="\
    prepare_coordinator_machine.sh \
    prepare_incredibuild_machine.sh \
    remove_coordinator_package.sh \
    remove_incredibuild_package.sh \
    OS"

function __wait() {
    while [ -e /proc/$1 ]
    do
        echo -ne "."
        sleep 1;
    done
    echo -ne " done"
    echo ""
}

function create_package_name(){
    revision=$(git rev-parse HEAD)
    current=$(git describe --all --exact-match ${revision})
    echo "######   CURRENT REVISION IS [${revision}]"
    if [[ "$current" == *tags* ]]
    then
        suffix=${current:5}
        echo "######   CURRENT VERSION IDENTIFIED [${suffix}]"
    else
        echo "######   IT IS DIRTY RELEASE, PLEASE CREATE TAG"
        suffix=dirty_${revision}
    fi
    eval "$1=incredibuild_linux_$suffix.tar.bz2"
}

package_name=?
create_package_name package_name
echo -ne "######   Generating [${package_name}] ..."
tar cjf ${package_name} ${PACKAGE_ITEMS_LIST} &
__wait `jobs -p`
