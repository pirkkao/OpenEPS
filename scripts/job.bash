#!/bin/bash
#SBATCH -p test
#SBATCH -J test
#SBATCH -t 5
#SBATCH -N 2
#SBATCH --ntasks-per-node=16
#SBATCH -o out
#SBATCH -e err

# A script to run an ensemble of models for N-dates.
#
# Optionally an iterative parameter search type algorithm can be enabled.
#

# Stop execution in case of error. More specifically, stop if the last
# command of the line does not return zero.
set -e
printf "\n\n4) Now in job.bash\n"

# Helper function for formatting dates (YYYYMMDD)
function day {
    date +%Y%m%d -d "$1"
} # THIS SHOULD EITHER BE IN HOUR FORMAT OR YOU SHOULD USE mandtg

# Set program source, work directories and available resources
for f in sources/*; do source $f; done

# Prepare input for the first batch of jobs
cd $DATA
test -d $SDATE || cp -r ${SCRI}/$SDATE .

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

export EVALUATE GENPARS GENLINK RUNEPS
export INFILE LINKFILE OUTFILE OUTPUTS NEW_INPUTS DATA cdate


# Set programs
pargen=${SCRI}/pargen
model_link=${SCRI}/model_link
model_run=$MODEL_EXE
funceval=${SCRI}/funceval
makefile=${SCRI}/makefile

INFILE=input
LINKFILE=
OUTFILE=output
POSTPRO=eval
GENPARS="$serial ${pargen}"
#GENPARS="echo"
GENLINK="$serial ${model_link}"
RUNEPS="$GENLINK ; $parallel ${model_run} -e teps"
#RUNEPS="echo > output"
EVALUATE="$serial $funceval"

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
    #OUTPUTS=${flist//\/input/\/output}
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
