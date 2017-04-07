#!/bin/bash

all_members () {
    local first_mem=$1
    local last_mem=$2
    local batch=$3
    local date=$4
    local imem
    for ((imem=first_mem;imem<=last_mem;imem++)); do
        printf "${date}pert%03d/%s " $imem $batch
    done
}

one_member () {
    local imem=$1
    local target=$2
    local needed=$3
    local date=${4:-""}
    local date2=${5:-""}
    if [ ! -z $needed ]; then
	printf "${date}pert%03d/%s : ${date2}pert%03d/%s" $imem $target $imem $needed
    else
	printf "${date}pert%03d/%s :" $imem $target
    fi
}
