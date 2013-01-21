#!/bin/bash
file_size=$1
files_number=$2
tests_number=$3

function test_arg_conditions() {
    if [[ -z $file_size  || -z $files_number || -z $tests_number ]];
    then
        echo "please use $0 [file size in megabytes] [files number to generate] [test repeat number]";
        exit -1;
    fi
}

function generate_files() {
    let size=$file_size*1024
    echo "Generating files for tests"
    for (( i=1; $i<=$files_number; i=$i+1 )); do
        echo "test $i";
        dd if=/dev/urandom of=rand_test$i bs=1024 count=$size;
    done
}

function run_md5_test() {
    for (( i=1; $i<=$files_number; i=$i+1 )); do
        XgSubmit -c PROCESS_A -r "-c md5sum -r \"rand_test$i\"";
    done
}

function delay() {
    echo "Waiting with XgWait";
    XgWait;
    echo "Sleep 10 second";
    sleep 10;
}

test_arg_conditions
echo "Genreating files for tests"
generate_files
echo "Run fresh test"
run_md5_test
echo "Run test, assume cached";
for (( k=1; $k<=$tests_number; k=$k+1 )); do
    delay;
    run_md5_test;
done
