#!/bin/bash
OUT_PUT=$1

function test_arg_conditions() {
    if [[ -z $OUT_PUT ]];
    then
        echo "please use $0 [results_out_put_file]";
        exit -1;
    fi
}

function wait() {
    echo "Waiting $1 seconds"
    sleep $1
}

function restart_services() {
    sudo service incredibuild stop
    wait 1
    sudo /etc/init.d/clean_incredibuild_log.sh
    wait 1
    sudo service incredibuild start
    wait 1
}

function submit_tasks() {
    XgSubmit -c "mount > unionfs_etc.txt" -r "";
    XgSubmit -c "cat /proc/mounts > unionfs_proc.txt" -r "";
    sleep 1
    XgWait
    sleep 1
}

function print_test_results() {
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00005 – Initiator machine create Slot Virtualization with Union of local system and network file system
    - Our target is to show that we able to present/use local machine filesystem murged with NFS
        - One reason is to be able to avoid cache of system library
        - Another reason could be thta we want to use local system files for system critical path
    - Currently we use /proc and /dev subsytem as union with NFS system
        - We will show this benefit as proper knowledge about local computer
            - Will show mounting system as real and as virtualized

#####################################################################################################################################

EOF
    cat << EOF >> $OUT_PUT


#####################################################################################################################################

UnionFS present /proc from Build Machine, present mount:

EOF
    cat unionfs_proc.txt >> $OUT_PUT
    cat << EOF >> $OUT_PUT


UnionFS present /etc from Initiator Machine, present mount:

EOF
    cat unionfs_etc.txt >> $OUT_PUT
    cat << EOF >> $OUT_PUT


#####################################################################################################################################

Incredibuild LOG:
EOF
    sudo sh -c "cat /var/log/incredibuild >> $OUT_PUT"
}

test_arg_conditions
echo "Start $0 ...."
restart_services
submit_tasks
print_test_results
echo "Test is finished, please check file $OUT_PUT"
gedit $OUT_PUT &
