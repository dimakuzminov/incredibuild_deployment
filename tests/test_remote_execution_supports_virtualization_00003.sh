#!/bin/bash
OUT_PUT=$1
input_file=I_Dont_Exists
user_id=$(whoami)

function test_arg_conditions() {
    if [[ -z $OUT_PUT ]];
    then
        echo "please use $0 [results_out_put_file]";
        exit -1;
    fi
}

function restart_services() {
    sudo /etc/init.d/clean_incredibuild_log.sh
    sleep 1
    sudo service incredibuild stop
    sleep 1
    sudo service incredibuild start
    sleep 1
}

function submit_tasks() {
    XgSubmit -c "mount > mount.txt" -r "";
    XgSubmit -c "cat /proc/mounts > remote_mount.txt" -r "";
    sleep 1
}

function print_test_results() {
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00003 – Initiator machine create Slot (Helper Machine) Virtualization on remote machine
    - In this test we run remote mount to ensure that virtualization is correct
    - We also using UnionFs infrustructure, we access to machine physical mount to present NFS and folder system
    - We present
        - Mount on remote machine. It shows physical
        - Mount on remote machine from virtualization. It hides nfs connection and shows our machine nfs
#####################################################################################################################################

EOF

    cat << EOF >> $OUT_PUT


#####################################################################################################################################
Mount on remote machine:
    - Initiator machine ip could be found in mount "nfs" lines
    - Initiator machine tree could be found in same line

EOF
    cat remote_mount.txt | grep nfs >> $OUT_PUT
    cat << EOF >> $OUT_PUT


#####################################################################################################################################
Mount on remote machine from virtualization:
    - Full mount list
    - Please notice we don't see nfs sections, our virtualization is full

EOF
    cat mount.txt >> $OUT_PUT
    cat << EOF >> $OUT_PUT


#####################################################################################################################################

Incredibuild LOG:
EOF
    XgWait
    sudo sh -c "cat /var/log/incredibuild >> $OUT_PUT"

}

test_arg_conditions
echo "Start $0 ...."
restart_services
submit_tasks
print_test_results
echo "Test is finished, please check file $OUT_PUT"
gedit $OUT_PUT &
