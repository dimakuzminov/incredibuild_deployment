#!/bin/bash
tests_number=$1

function generate_file() {
    dd if=/dev/zero of=dummy bs=512 count=10240
}

function run_test() {
    for (( i=1; $i<=$tests_number; i=$i+1 )); do
        for j in {A..B}; do
            for k in {B..C}; do
                XgSubmit -c PROCESS_$j -r "-c PROCESS_$k -r \" -s dummy -d test_dummy$i\"";
            done
        done
    done
}

echo "Genreating file for tests"
generate_file
echo "Run test"
run_test
