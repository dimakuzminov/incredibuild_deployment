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
    XgSubmit -c PROCESS_A -r "-c PROCESS_B -r \" -s $input_file -d test_dummy \"";
    XgSubmit -c PROCESS_A -r "-c PROCESS_C -r \" -s $input_file -d test_dummy \"";
    sleep 1
    XgWait
    sleep 1
}

function print_test_results() {
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00002 – tasks are queued on local machine and executed on remote machine. stdErr is returned back to initiator machine
    - In this test we are running two wrong scripts
    - XgSubmit -c PROCESS_A -r "-c PROCESS_B -r \" -s $input_file -d test_dummy \"";
        - The error should be seen on Process_B execution, since file $input_file doesn't exist
        - It is not STDERR for us since Process_A catch this event, we olny see it as STD_OUT
    - XgSubmit -c PROCESS_A -r "-c PROCESS_C -r \" -s $input_file -d test_dummy \"";
        - This one is STD_ERR should be catch by us, because Process_A cannot catch it, it is system error. It is generated
            because Process_C doesn't exist
This test should present that remote execution returns STDOUT
    - [ERROR] message, as submessage for missing file. STD_OUT
    - [ERROR] message in first column, for missing process (system halt). STD_ERR
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
