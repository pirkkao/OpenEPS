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

for i in $(seq 0 $ENS); do
    # Add 1-2 leading zeros if ens member < 100
    if [ $i -lt 10 ]; then i=00$i; elif [ $i -lt 100 ]; then i=0$i; fi
    mkdir -p  $DATA/$SDATE/pert$i
    echo >    $DATA/$SDATE/pert$i/input
done

# Print the makefile in explicit form
makemake () {
    cdate=$1
    njobs=$2
    printf ".PHONY: all\n\n" 
    printf "all: %s\n\n" "$NEW_INPUTS"
    printf "%s : %s\n"   "$NEW_INPUTS" "$OUTPUTS2"
    for item in $NEW_INPUTS; do makedirs="$makedirs $(dirname $item)"; done
    printf "\tmkdir -p %s\n" "$makedirs"
    printf "\t%s %s > %s\n\n" "$GENPARS" "$OUTPUTS2" "$NEW_INPUTS"
    
    n=0
    fflist=( $flist )
    for item in $OUTPUTS2; do
	printf "%s : %s\n" "$item" "${fflist[$n]}"
	printf "\tcd %s ; echo > pp\n" "$(dirname $item)"
	(( n+=1 ))
    done
    
    n=0
    fflist=( $flist )
    for item in $OUTPUTS; do
	printf "%s : %s\n" "$item" "${fflist[$n]}"
	printf "\tcd %s ; %s\n" "$(dirname $item)" "$RUNEPS"
	(( n+=1 ))
    done
}

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
export INFILE OUTFILE OUTPUTS NEW_INPUTS DATA cdate PPFILE OUTPUTS2

# TARGET_GOAL   - the final target that make will try to reach
# TARGET_SECND  - the target required by TARGET_GOAL
# TARGET_FIRST  - the target required by TARGET_SECND
# TARGET_ZERO   - the target required by TARGET_FIRST
#
# RULE_GOAL     - commands to execute once TARGET_SECND is available
# RULE_SECND    - commands to execute once TARGET_FIRST is available
# RULE_FIRST    - commands to execute once TARGET_START is available
# RULE_ZERO     - commands to execute if nothing has yet been done

TARGET_GOAL=date_finished
TARGET_SECND=ppfile
TARGET_FIRST=outfile
TARGET_ZERO=infile

RULE_GOAL="echo > date_finished"
RULE_SECND="cd $@ ; echo > ppfile"
RULE_FIRST="cd $@ ; echo > outfile"
RULE_ZERO="cd $@ ;  echo > infile"

# Set programs
pargen=${SCRI}/pargen
makefile=${SCRI}/makefile

INFILE=input
OUTFILE=output
PPFILE=pp

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
    flist=$(ls $cdate/pert*/input)
    flist=${flist//[$'\t\r\n']/ }
    OUTPUTS=${flist//\/input/\/output}
    OUTPUTS2=${flist//\/input/\/pp}
    NEW_INPUTS=${flist//${cdate}\//${ndate}\/}
    
    # temp solution
    mkdir -p $cdate/inistates

    makemake > ${cdate}/foomakefile
    make -f $makefile -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
