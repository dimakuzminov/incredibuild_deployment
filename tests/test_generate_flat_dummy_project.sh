#!/bin/bash
project_name=$1
number_of_files=$2
number_of_functions=$3

function test_arg_conditions() {
    if [[ -z $project_name || -z $number_of_files || -z $number_of_functions ]];
    then
        echo "please use $0 [project name] [number of cpp files in project] [number of functions in each cpp file]";
        exit -1;
    fi
}

function create_project() {
    echo "Creating project $project_name"
    rm -fr $project_name
    mkdir $project_name
    pushd $project_name
    cat << EOF > Makefile
CPPSOURCES := \$(shell ls *.cpp 2>/dev/null)
OBJECTS := \$(CPPSOURCES:.cpp=.o)
DEPFILES := \$(OBJECTS:%.o=.%.d)
TARGET ?= libdima_test.so

CPPFLAGS += -g -fPIC 
LDFLAGS += -g -lstdc++ -ldl -shared -Wl,-Bsymbolic

all:\$(TARGET)

\$(TARGET):\$(OBJECTS)
	g++ -o \$@ \$^ \$(LDFLAGS)

clean:
	rm -f \$(TARGET) *.o *~ \#*
	rm -f .*.P

DF=\$(*F)

%.o : %.cpp
	g++ \$(CPPFLAGS) -c \$*.cpp
	g++ -MM \$(CPPFLAGS) \$*.cpp > \$*.d 

-include \$(DEPFILES)
EOF
popd
}

function generate_functions() {
    for (( k=1; $k<=$number_of_functions; k=$k+1 )); do
        cat << EOF >> $1
typedef struct {
    int status[255];
} __$2_$3_data_$k;

__$2_$3_data_$k g_$2data_$3_$k;

void $2_$3_print_$k( __$2_$3_data_$k *data )
{
    printf( "%s:%s:%d[%p]\n", __FILE__, __FUNCTION__, __LINE__, data );
}

EOF
    done
}

function generate_cpp_files() {
    pushd $project_name
    for (( i=1; $i<=$number_of_files; i=$i+1 )); do
        filename="$project_name"_name_"$i".cpp 
        echo "Generating file $filename"
        cat << EOF > $filename
#include <stdio.h>

EOF
        generate_functions $filename $project_name $i
    done
    popd
}

function generate_profile_file() {
    pushd $project_name
    cat << EOF > profile.xml
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<Profile FormatVersion="1">
  <Tools>
    <Tool Filename="make" AllowIntercept="true" />
    <Tool Filename="g++" AllowRemote="true" ArgumentsExclude="-o"/>
  </Tools>
</Profile>
EOF
    popd
}

test_arg_conditions
create_project
generate_cpp_files
generate_profile_file
