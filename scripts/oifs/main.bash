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


#--------------------------------------------------------------
# TEMP INIT
#--------------------------------------------------------------
# Dummy routine for generating initial input and parameter
# perturbations
#
mkdir -p $SCRI/$SDATE/inistates
cd $SCRI/$SDATE
cat <<EOF > params
2.5
2.6
2.7
2.4
3.2
1.2
1.0
5.1
1.4
EOF

for i in $(seq $ENS); do
 mkdir -p $SCRI/$SDATE/job$i
 echo >   $SCRI/$SDATE/job$i/input
 sed -n ${i}p params > job${i}/para

 if false; then
 # Initial states
 #
 i=$(echo "$i - 1" | bc)
 if [ $i -eq 0 ]; then
  name=ctrl
 elif [ $i -lt 10 ]; then
  name=pert00$name
 fi
 for item in GG SH; do # CL GG SH; do
  if [ $item == GG ]; then
   cp -f ${INIBASEDIR}/$SDATE/${name}_ICM${item}_INIUA $SCRI/$SDATE/inistates/${name}_ICM$item${EXPS}INIUA
  fi
  cp -f  ${INIBASEDIR}/$SDATE/${name}_ICM${item}_INIT $SCRI/$SDATE/inistates/${name}_ICM$item${EXPS}INIT
 done
 fi
 
done

# Prepare input for the first batch of jobs
cd $DATA
test -d $SDATE || cp -r ${SCRI}/$SDATE .


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
model_link=${SCRI}/link.bash
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
