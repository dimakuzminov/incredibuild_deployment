#!/bin/bash
OUT_PUT=$1
files_number=100
timer_result=timer_result
tests_number=5

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

function generate_files() {
    echo "Generating files for tests"
    for (( i=1; $i<=$files_number; i=$i+1 )); do
        echo "creating file  rand_test$i ...";
        dd if=/dev/urandom of=rand_test$i bs=1024 count=1024;
    done
}

function submit_tasks() {
    echo "Fill incredibuild service with $files_number tasks ..."
    for (( j=1; $j<=$files_number; j=$j+1 )); do
        XgSubmit -c PROCESS_A -r "-c md5sum -r \"rand_test$j\"";
    done
    echo "Wait execution to finish..."
    XgWait
}

function tests_in_loop() {
    for (( k=1; $k<=$tests_number; k=$k+1 )); do
        (time submit_tasks > /dev/null) &> $timer_result$k
        wait 5
    done
}

function print_test_results() {
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00004 – Initiator machine create Slot Virtualization with Cache mechanisms 
    - This test present cache mechanism effectiveness
    - First we generate 100 random files, that drop cache from Slot (BuildMachine) remote machine
    - Then we run 100 tasks, it should require maximum time
    - After that we run other 4 times test, each test with 100 tasks
        - These 4 addtional tests should show that time is reduced till it becomes stable

#####################################################################################################################################

EOF
    cat << EOF >> $OUT_PUT


#####################################################################################################################################
TEST_CACHE_TABLE:

EOF
    l=1
    echo "----------------------------------------------------------------" >> $OUT_PUT;
    echo "task number $l execution time, new code. cache shouldn't be used" >> $OUT_PUT;
    cat $timer_result$l >> $OUT_PUT;
    for (( l=2; $l<=$tests_number; l=$l+1 )); do
        echo "----------------------------------------------------------------" >> $OUT_PUT;
        echo "task number $k execution time, testing cache" >> $OUT_PUT;
        cat $timer_result$l >> $OUT_PUT;
    done

    cat << EOF >> $OUT_PUT


#####################################################################################################################################

Incredibuild LOG:
EOF
    sudo sh -c "cat /var/log/incredibuild >> $OUT_PUT"

}

test_arg_conditions
echo "Start $0 ...."
clean_log
generate_files
restart_services
tests_in_loop
print_test_results
echo "Test is finished, please check file $OUT_PUT"
gedit $OUT_PUT &
