#!/bin/bash
OUT_PUT=$1
file_size=100
files_number=10
timer_result=timer_result
tests_number=5
test_file_prefix=test_00007_rand
temp_test_output=test_00007_out
temp_test_output_current=

function test_arg_conditions() {
    if [[ -z $OUT_PUT ]];
    then
        echo "please use $0 [results output file]";
        exit -1;
    fi
}

function wait() {
    echo "Waiting $1 seconds"
    sleep $1
}

function restart_services_clean_log() {
    sudo service incredibuild stop
    wait 1
    sudo /etc/init.d/clean_incredibuild_log.sh
    wait 1
    sudo service incredibuild start
    wait 1
    firefox http://localhost:8080/incredibuild/monitor/default.html &
}

function restart_services() {
    sudo service incredibuild stop
    wait 1
    sudo service incredibuild start
    wait 1
    firefox http://localhost:8080/incredibuild/monitor/default.html &
}

function generate_files() {
    let size=$file_size*1024
    echo "Generating files for tests"
    for (( i=1; $i<=$files_number; i=$i+1 )); do
        echo "creating file  $test_file_prefix$i ...";
        dd if=/dev/urandom of=$test_file_prefix$i bs=1024 count=$size;
    done
}

function clean_files() {
    let size=$file_size*1024
    echo "Generating files for tests"
    for (( i=1; $i<=$files_number; i=$i+1 )); do
        echo "remove file  $test_file_prefix$i ...";
        rm -f $test_file_prefix$i;
    done
    rm -f  $timer_result*
    rm -f  $temp_test_output*
}

function submit_tasks() {
    echo "Fill incredibuild service with $files_number tasks ..."
    for (( j=1; $j<=$files_number; j=$j+1 )); do
        XgSubmit -c PROCESS_A -r "-c md5sum -r \"$test_file_prefix$j\"";
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

function print_temp_results() {
    echo "----------------------------------------------------------------" > $temp_test_output_current;
    echo "result from test number [$1] on this machine" >> $temp_test_output_current;
    echo "----------------------------------------------------------------" >> $temp_test_output_current;
    for (( l=1; $l<=$tests_number; l=$l+1 )); do
        echo "----------------------------------------------------------------" >> $temp_test_output_current;
        echo "task number $k execution time" >> $temp_test_output_current;
        cat $timer_result$l >> $temp_test_output_current;
    done
}

function print_test_results() {
    let cache_size=$file_size*$files_number
    cat << EOF > $OUT_PUT
#####################################################################################################################################
Test 00007 – Slot Virtualization session cached big files 
    - this is complicated test
    - we will check if remote machine (Build Machine) can cache $cache_size Mbytes
    - you need to select two Initiator machines - A and B
    - run this script on machine A and answer "n"
    - run this script on mahcine B and answer "n"
    - run this script again on Machine A and answer "y"
        - report would be generated for you
    howto read:
    - follow section TEST_CACHE_TABLE
        - you will find results from running entire test from your machine on fresh files that are not cached
            - it would be result from 1 test on this machine
        - you will find results from running entire test from your machine on already cached data
            - it would be result from 2 test on this machine
    - the idea is that on second test numbers are pretty low
    - this test will check can we cache large files in system

#####################################################################################################################################

EOF
    cat << EOF >> $OUT_PUT


#####################################################################################################################################
TEST_CACHE_TABLE:

EOF
    cat $temp_test_output"1" >> $OUT_PUT
    cat $temp_test_output"2" >> $OUT_PUT
    cat << EOF >> $OUT_PUT

#####################################################################################################################################

Incredibuild LOG:
EOF
    sudo sh -c "cat /var/log/incredibuild >> $OUT_PUT"

}

while true; do
    cat << EOF
#####################################################################################################################################
Test 00007 – Slot Virtualization session cached big files 
    - this is complicated test
    - you need to select two Initiator machines - A and B
    - run this script on machine A and answer "n"
    - run this script on mahcine B and answer "n"
    - run this script again on Machine A and answer "y"
        - report would be generated for you


EOF
    read -p "Is this secondary run?" yn
    case $yn in
        [Yy]* ) 
            test_arg_conditions
            temp_test_output_current=$temp_test_output"2"
            echo " ################# $temp_test_output_current"
            echo "Start $0 ...."
            restart_services
            tests_in_loop
            print_temp_results 2
            print_test_results
            echo "Test is finished, please check file $OUT_PUT"
            gedit $OUT_PUT &
            break;;
        [Nn]* )
            temp_test_output_current=$temp_test_output"1"
            echo " ################# $temp_test_output_current"
            echo "Start $0 ...."
            clean_files
            generate_files
            restart_services_clean_log
            tests_in_loop
            print_temp_results 1
            echo "Test is finished, run test $0 on next machine"
            break;;
        * ) echo "Please answer yes or no.";;
    esac
done
