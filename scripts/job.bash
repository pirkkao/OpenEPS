#!/bin/bash
#SBATCH -p test
#SBATCH -J test
#SBATCH -t 5
#SBATCH -N 2
#SBATCH --ntasks-per-node=16
#SBATCH -o out
#SBATCH -e err

# A script to run iterative parameter search type algorithm.

# Stop execution in case of error. More specifically, stop if the last
# command of the line does not return zero.
set -e

# Helper function for formatting dates (YYYYMMDD)
function day {
    date +%Y%m%d -d "$1"
} # THIS SHOULD EITHER BE IN HOUR FORMAT OR YOU SHOULD USE mandtg

# Set program source and work directories
scripts=${1}
runs=${2}

# Set run steps
startdate=${3}
enddate=${4} #$(day "$startdate + 1 days")
dstep=${5}

# Prepare input for the first batch of jobs
mkdir -p $runs
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
POSTPRO=postp
GENPARS="$launcher2 ${pargen}"
GENLINK="$launcher2 ${model_link}"
RUNEPS="$launcher ${model_run} -e teps"
EVALUATE="$launcher2 $funceval"

# Export information for the model
export OIFS_GRIB_API_DIR=/home/ollin/Install_software/grib-api
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OIFS_GRIB_API_DIR/lib
export GRIB_SAMPLES_PATH=$OIFS_GRIB_API_DIR/share/grib_api/ifs_samples/grib1_mlgrib2
export OMP_NUM_THREADS=1
export DR_HOOK=1

ulimit -s unlimited

cdate=$startdate
while [ $cdate -le $enddate ]; do
    echo "Processing date $cdate"
#    ndate=$(day "$cdate + 1 day")
    ndate=`exec ../scripts/./mandtg $cdate + $dstep`
    flist=$(ls $cdate/job*/input)
    flist=${flist//[$'\t\r\n']/ }
    OUTPUTS=${flist//\/input/\/output}
    NEW_INPUTS=${flist//${cdate}\//${ndate}\/}
    # temp solution
    mkdir -p $cdate/inistates

    #make -f $makefile -j $njobs
    make -f $makefile -j 1
    
    cdate=$ndate
done
    
set +e
