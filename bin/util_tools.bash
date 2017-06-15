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

one_member_2dep () {
    local imem=$1
    local target=$2
    local needed1=$3
    local needed2=$4
    local date=${5:-""}
    local date2=${6:-""}
    printf "${date}pert%03d/%s : ${date2}pert%03d/%s ${date2}pert%03d/%s" $imem $target $imem $needed1 $imem $needed2
}


print_rule () {
    # Write out explicit forms of make target-prerequisite trees
    #
    local imem

    # INDIVIDUAL
    # pert000/target : pert000/prereq
    # pert001/target : pert001/prereq
    # ...
    if [ $applyto == individual ]; then
	for imem in $(seq 0 $ENS); do
	    printf "%s : %s\n" "$(parse_dirs ${1} $imem)" "$(parse_dirs ${2} $imem)"
	    printf "\t%s\n" "${!3}"
	done

    # ALL
    # pert000/target pert001/target ... : pert000/prereq pert001/prereq ...
    elif [ $applyto == all ]; then
	printf "%s : %s\n" "$(parse_dirs ${1} "$(seq 0 $ENS)")" \
	                   "$(parse_dirs ${2} "$(seq 0 $ENS)")"
	printf "\t%s\n" "${!3}"

    # NEED ALL
    # pert000/target : pert000/prereq pert001/prereq ...
    # pert001/target : pert000/prereq pert001/prereq ...
    # ...
    elif [ $applyto == need_all ]; then
	printf "%s : %s\n" "$(parse_dirs ${1} "$(seq 0 $ENS)")" \
	                   "$(parse_dirs ${2} "$(seq 0 $ENS)")"
	printf "\t%s\n" "${!3}"

    # MAIN ALL
    # target : pert000/prereq pert001/prereq ...
    elif [ $applyto == main_all ]; then
	printf "%s : %s\n" "$(parse_dirs ${1} "$(seq 0 $ENS)")" \
	                   "$(parse_dirs ${2} "$(seq 0 $ENS)")"
	printf "\t%s\n" "${!3}"
	
    # SINGLE
    # pert000/target : pert000/prereq
    elif [ $applyto == single ]; then
	printf "%s : %s\n" "$(parse_dirs ${1} $4)" "$(parse_dirs ${2} $4)"
	printf "\t%s\n" "${!3}"
    fi
}

parse_dirs () {
    # Parse directory structure into make targets/prerequisites
    #
    local item
    local imem
    local split_item
    
    for item in ${!1}; do
	# Change write order if user wants to write to different
	# main folder
	if [[ $item == *DIR* ]]; then
	    split_item=(${item//DIR/ })
	    for imem in ${2}; do
		printf "%s%s%03d%s " ${split_item[0]} $pert_struct $imem ${split_item[1]}
	    done

	elif [[ $item == *MAIN* ]]; then
	    # Detect MAIN and discard first /
	    split_item=(${item//MAIN// })
	    printf "%s" ${split_item[1]:1}
	    
	else
	    for imem in ${2}; do
		printf "%s%03d/%s " $pert_struct $imem $item
	    done
	fi
    done
}


write_makefile () {
    # Loop through all targets
    #
    local irule=1
    local target prereq recipe applyto

    # Print header lines
    printf "%s\n\n"    ".SECONDARY :" # KEEP ALL FILES

    printf "%s\n"    ".PHONY : all"
    printf "%s\n"    "all : $(parse_dirs target_1)"

    while [ 1 ]; do
	target=target_$irule
	prereq=prereq_$irule
	recipe=recipe_$irule
	applyto=applyto_$irule
	if [ ! -z ${!target} ]; then
	    export applyto=${!applyto}
	    print_rule $target $prereq $recipe
	    (( irule += 1 ))
	else
	    break
	fi
	echo
	echo
    done
}
