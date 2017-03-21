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

# Helper function for formatting dates (YYYYMMDD)
function day {
    date +%Y%m%d -d "$1"
} # THIS SHOULD EITHER BE IN HOUR FORMAT OR YOU SHOULD USE mandtg

# Set program source and work directories
source sources/*

scripts=$SCRI
runs=$DATA

# Set run steps
startdate=$SDATE
enddate=$EDATE
dstep=$DSTEP


# Prepare input for the first batch of jobs
cd $runs
test -d $startdate || cp -r ${scripts}/$startdate .

# Number of (MPI) jobs in a batch
njobs=$(ls -1 ${runs}/${startdate} | wc -l)

# Number of tasks per job
: ${SLURM_JOB_NUM_NODES:=2}
: ${SLURM_NTASKS_PER_NODE:=16}
tasks=$(( $SLURM_JOB_NUM_NODES * $SLURM_NTASKS_PER_NODE ))
jobtasks=$(( $tasks / $njobs ))

# (MPI) launcher
launcher=$(basename $(which aprun 2> /dev/null || which srun 2> /dev/null || which mpirun 2> /dev/null || which bash ))
case "$launcher" in
    aprun|srun)
	launcher="$launcher -n $jobtasks bash"
	launcher2=$launcher
	    ;;
    mpirun)
	launcher="$launcher -np 2"
	launcher2="bash"
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
export INFILE LINKFILE OUTFILE OUTPUTS NEW_INPUTS runs cdate

echo "Number of concurrent jobs $njobs"
echo "Entering $runs"
echo $launcher

# Set programs
pargen=${scripts}/pargen
model_link=${scripts}/model_link
model_run="/home/ollin/projects/OIFS/oifs38r1v04/make/gnu-opt/oifs/bin/master.exe"
funceval=${scripts}/funceval
makefile=${scripts}/makefile

INFILE=input
LINKFILE=
OUTFILE=output
POSTPRO=eval
GENPARS="$launcher2 ${pargen}"
GENLINK="$launcher2 ${model_link}"
RUNEPS="$GENLINK ; $launcher ${model_run} -e teps"
#RUNEPS="echo > output"
EVALUATE="$launcher2 $funceval"

# Export information for the model
export OIFS_GRIB_API_DIR=/home/ollin/Install_software/grib-api
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OIFS_GRIB_API_DIR/lib
export GRIB_SAMPLES_PATH=$OIFS_GRIB_API_DIR/share/grib_api/ifs_samples/grib1_mlgrib2
export OMP_NUM_THREADS=1
export DR_HOOK=1

# Increase stack memory (model may crash with SEGV otherwise)
ulimit -s unlimited

cdate=$startdate
while [ $cdate -le $enddate ]; do
# Log
    echo                                >> $runs/../master.log
    echo "Running ens for $cdate"       >> $runs/../master.log
    date | echo `exec cut -b13-21` init >> $runs/../master.log

    echo "Processing date $cdate"
#    ndate=$(day "$cdate + 1 day")
    ndate=`exec ../scripts/./mandtg $cdate + $dstep`
    flist=$(ls $cdate/job*/input)
    flist=${flist//[$'\t\r\n']/ }
    #OUTPUTS=${flist//\/input/\/output}
    OUTPUTS=${flist//\/input/\/output}
    NEW_INPUTS=${flist//${cdate}\//${ndate}\/}
    # temp solution
    mkdir -p $cdate/inistates

    #make -f $makefile -j $njobs
    make -f $makefile -j 2
    
    cdate=$ndate
done
    
set +e
