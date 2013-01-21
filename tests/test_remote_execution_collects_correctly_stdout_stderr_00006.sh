#!/bin/bash
OUT_PUT=$1
tests_number=25

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
    firefox http://localhost:8080/incredibuild/monitor/default.html &
}

function submit_tasks() {
    dd if=/dev/zero of=dummy bs=1024 count=1024
    for (( i=1; $i<=$tests_number; i=$i+1 )); do
        for j in {A..B}; do
            for k in {B..C}; do
                XgSubmit -c PROCESS_$j -r "-c PROCESS_$k -r \" -s dummy -d test_dummy$i\"";
            done
        done
    done
    sleep 1
    XgWait
    sleep 1
}

function print_test_results() {
    let all_tests=$tests_number*4
    let error_tests=$tests_number*3
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00006 – tasks a, a', b, b'  will be used, stdOut/stdErr returned back to initiator machine and identify clearly errors
    - Test procedure is in form
        for ( i=1; i<=$tests_number; i++ ); do
            for j in {A..B}; do
                for k in {B..C}; do
                    XgSubmit -c PROCESS_$j -r "-c PROCESS_$k -r \" -s dummy -d test_dummy$i\"";
                done
            done
        done
    - task a  = PROCESS_A. this is correct
    - task a' = PROCESS_B. The process itself is correct, however it cannot accept parameter "-r" and it generates STD_ERR
    - task b  = PROCESS_B with correct parameters. this is correct
    - task b' = PROCESS_C. This process doesn't exists and generates STD_ERR
This test should present that remote execution identifies correctly STD_ERR and STD_OUT
    - we have following 4 combinations, $all_tests tests. There are $error_tests error tests and $tests_number correct tests 
        - a b  : correct combination, it is $tests_number correct results
        - a' b : bad combination, it is $tests_number error results
        - a b' : bad combination, it is $tests_number error results
        - a' b': bad combination, it is $tests_number error results
#####################################################################################################################################

EOF
    cat << EOF >> $OUT_PUT

#####################################################################################################################################
    In this section we list all STD_ERR lines

EOF
    grep "\[ERROR\]\[GridServer_Slot.cpp:165\]\[function _executeRemoteProcesses\]" /var/log/incredibuild >> $OUT_PUT
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
