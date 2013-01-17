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
    - We use our remote executio nto access remote machine (Build Machine)
    - We use following remote commands:
        - XgSubmit -c "mount > mount.txt" -r "";
            - This command shows remote machine partition table.
            - It will not show NFS connections. We use it to prove that virtualiztion is done and Build Machine Doesn't know that it
                exists remotely on network
            - NAME FOR TABLE - VIRTUALIZATION_LOCAL_MOUNT_TABLE
        - XgSubmit -c "cat /proc/mounts > remote_mount.txt" -r "";
            - This command use UnionFs system
            - We access /proc that is primary access local resources on remote machine
            - We present all NFS connections for each Initiator machine that is using this Build Machine
            - The line of NFS that shows in first column / root folder is our virtualiztion point for our Initiator Machine
                - from left you can find what Initiator Machine ask for this Slot (session) virtualization
            - NAME FOR TABLE - LOCAL_MOUNT_TABLE
            

#####################################################################################################################################

EOF

    cat << EOF >> $OUT_PUT


#####################################################################################################################################
LOCAL_MOUNT_TABLE:

EOF
    cat remote_mount.txt | grep nfs >> $OUT_PUT
    cat << EOF >> $OUT_PUT


#####################################################################################################################################
VIRTUALIZATION_LOCAL_MOUNT_TABLE:

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
