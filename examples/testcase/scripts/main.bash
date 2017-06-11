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
    . ${SCRI}/define_makefile.bash
    . ${SCRI}/write_makefile.bash  > foomakefile2

    # Execute
    make -f foomakefile2 -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
exit 1
