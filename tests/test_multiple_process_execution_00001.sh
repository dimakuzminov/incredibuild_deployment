#!/bin/bash
OUT_PUT=$1
number_of_tasks=100
input_file=dummy_test
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
    dd if=/dev/zero of=$input_file bs=1024 count=1024
    for (( i=1; $i<=$number_of_tasks; i=$i+1 )); do
        XgSubmit -c PROCESS_A -r "-c PROCESS_B -r \" -s $input_file -d test_dummy$i\"";
    done
    sleep 1
    XgWait
}

function print_test_results() {
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00001 – tasks are queued on local machine and executed on remote machine, stdOut returned back to initiator machine
    - There are more than 10 tasks buffered in queue. Check Queue increasing before tasks starts
    - "adding command to queue" - is identifying that tasks dropped to queue
    - For each tasks, use "test_dummy[number]" to identify life time of tasks.
    - Use Slot ID to follow life time of BuildMachine
This test should present that remote execution returns STDOUT
    - use Slot ID[number] to follow process output
Critical:
    - all tests run only with ssh session
    - log file tested only on Initiator machine
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
