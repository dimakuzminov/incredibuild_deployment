#!/bin/bash

PACKAGE_ITEMS_LIST="\
    prepare_coordinator_machine.sh \
    prepare_incredibuild_machine.sh \
    remove_coordinator_package.sh \
    remove_incredibuild_package.sh \
    OS"

function create_package_name(){
    revision=$(git rev-parse HEAD)
    current=$(git describe --all --exact-match ${revision})
    echo "Current tag or revision is [${revision}]"
    if [[ "$current" == *tags* ]]
    then
        suffix=${current:5}
    else
        echo "It is dirty release, please create tag"
        suffix=dirty_${revision}
    fi
    eval "$1=incredibuild_linux_$suffix.tar.bz2"
}

package_name=?
create_package_name package_name
echo "Generating [${package_name}]..."
tar cjvf ${package_name} ${PACKAGE_ITEMS_LIST}
