#!/bin/bash
files_number=$1
tests_number=$2

function generate_files() {
    echo "Generating files for tests"
    for (( i=1; $i<=$files_number; i=$i+1 )); do
        echo "test $i";
        dd if=/dev/urandom of=rand_test$i bs=1024 count=1024;
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

echo "Genreating files for tests"
generate_files
echo "Run fresh test"
run_md5_test
echo "Run test, assume cached";
for (( k=1; $k<=$tests_number; k=$k+1 )); do
    delay;
    run_md5_test;
done
