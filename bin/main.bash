#!/bin/bash

# A script to run an ensemble of models for N-dates.
# Additional tasks can be set for each date by modifying the
# makefile generation (define_makefile.bash and write_makefile.bash)
#

# Stop execution in case of error. More specifically, stop if the last
# command of the line does not return zero.
#
set -e
printf "\n\n4) Now in main.bash\n"


# Set program source, work directories and available resources
#
for f in configs/*; do source $f; done


# Loop over dates
#
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
    ndate=`exec $WORK/./mandtg $cdate + $DSTEP`
    
    # Generate makefile for current date
    #. ${SCRI}/define_makefile.bash
    #. ${SCRI}/write_makefile.bash  > makefile_$cdate
    
    #make -f $makefile -j $njobs
    make -f makefile_$cdate -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
exit 1
