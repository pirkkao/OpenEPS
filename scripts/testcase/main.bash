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
for f in sources/*; do source $f; done


# Dummy routine for generating initial input
#
mkdir -p $DATA/$SDATE

for i in $(seq $ENS); do
 mkdir -p  $DATA/$SDATE/job$i
 echo >    $DATA/$SDATE/job$i/input
done

# (MPI) launcher
launcher=$(basename $(which aprun 2> /dev/null || which srun 2> /dev/null || which mpirun 2> /dev/null || which bash ))
case "$launcher" in
    aprun|srun)
	parallel="$launcher -n $CPUSPERMODEL"
	serial=$launcher
	    ;;
    mpirun)
	parallel="$launcher -np $CPUSPERMODEL"
	serial="bash"
	;;
esac

# Variables for make
#
# GENERATE   - command to generate NEW_INPUTS from OUTPUTS
# RUNEPS     - command to generate model output
# EVALUATE   - command to generate OUTPUTS from OLD_INPUTS
# INFILE     - name of the input file for EVALUATE command, must exist
# OUTFILE    - name of the output file for EVALUATE command
# OUTPUTS    - list of OUTFILEs 
# NEW_INPUTS - INFILEs for the next step, the goal of this make step

export GENPARS RUNEPS
export INFILE OUTFILE OUTPUTS NEW_INPUTS DATA cdate

# Set programs
pargen=${SCRI}/pargen
makefile=${SCRI}/makefile

INFILE=input
OUTFILE=output

GENPARS="echo"
RUNEPS="echo > output"

cd $DATA
cdate=$SDATE
while [ $cdate -le $EDATE ]; do
    # Log
    echo                                >> $WORK/master.log
    echo "Running ens for $cdate"       >> $WORK/master.log
    date | echo `exec cut -b13-21` init >> $WORK/master.log

    echo "   Processing date $cdate"
    ndate=`exec $SCRI/./mandtg $cdate + $DSTEP`
    flist=$(ls $cdate/job*/input)
    flist=${flist//[$'\t\r\n']/ }
    OUTPUTS=${flist//\/input/\/output}
    NEW_INPUTS=${flist//${cdate}\//${ndate}\/}
    
    # temp solution
    mkdir -p $cdate/inistates

    #make -f $makefile -j $njobs
    make -f $makefile -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
