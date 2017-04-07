#!/bin/bash

#
# A script to run an ensemble of models for N-dates.
# Optionally an iterative parameter search type algorithm can be enabled.
#

# Stop execution in case of error. More specifically, stop if the last
# command of the line does not return zero.
set -e
printf "\n\n4) Now in main.bash\n"


# Set program source, work directories and available resources
for f in configs/*; do source $f; done


# Dummy routine for generating initial input
#
mkdir -p $DATA/$SDATE

# Generate data structure for perturbations, add leading zeros so that $ENS
# can be LARGE
for i in $(seq 0 $ENS); do
    # Add leading zeros
    i=$(printf "%03d" $i)
    mkdir -p  $DATA/$SDATE/pert$i
    echo >    $DATA/$SDATE/pert$i/infile_new
done


# Targets and rules for makefile
#
# TARGET_1   - the final target that make will try to reach
# NEEDED_1   - dependencies of TARGET_1
# RULE_1     - 
#
# TARGET_2   - what TARGET_2 will produce
# NEEDED_2   - dependencies of TARGET_2
#
# TARGET_3   - what TARGET_3 will produce
# NEEDED_3   - dependencies of TARGET_3
#
# TARGET_4   - what TARGET_4 will produce
# NEEDED_4   - dependencies of TARGET_4
#
# TARGET_5   - what TARGET_5 will produce
# NEEDED_5   - dependencies of TARGET_5
#
# RULE_1    - commands to execute once NEEDED_1 are available
# RULE_2    - commands to execute once NEEDED_2 are available
# RULE_3    - commands to execute once NEEDED_3 are available
# RULE_4    - commands to execute once NEEDED_4 are available
# RULE_5    - commands to execute once NEEDED_5 are available

TARGET_5=infile
NEEDED_5=""
RULE_5='cd $(dir $@) ;  cp -f infile_new infile'
export TARGET_5 NEEDED_5 RULE_5

TARGET_4=oufile
NEEDED_4=$TARGET_5
RULE_4='cd $(dir $@) ; echo > outfile'
export TARGET_4 NEEDED_4 RULE_4

TARGET_3=infile_new
NEEDED_3=$TARGET_4
RULE_3='mkdir -p $(dir $@); cd $(dir $@); echo > infile_new'
export TARGET_3 NEEDED_3 RULE_3

TARGET_2=ppfile
NEEDED_2=$TARGET_4
RULE_2='cd $(dir $@) ; echo > ppfile'
export TARGET_2 NEEDED_2 RULE_2

TARGET_1=date_finished
RULE_1='echo > date_finished'
export TARGET_1 RULE_1 


# Set programs
makefile=${SCRI}/makefile

export cdate ndate
cdate=$SDATE
while [ $cdate -le $EDATE ]; do
    cd $DATA/$cdate
    # Log
    echo                                >> $WORK/master.log
    echo "Running ens for $cdate"       >> $WORK/master.log
    date | echo `exec cut -b13-21` init >> $WORK/master.log
    echo "   Processing date $cdate"
    
    # Define next date
    ndate=`exec $SCRI/./mandtg $cdate + $DSTEP`

    # Generate makefile for current date
    . ${SCRI}/write_makefile.bash  > foomakefile2

    # Execute
    make -f foomakefile2 -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
exit 1
