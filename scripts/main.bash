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

# Set program source, work directories and available resources
for f in configs/*; do source $f; done


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

for i in $(seq 0 $ENS); do
    # Add leading zeros
    i=$(printf "%03d" $i)
    mkdir -p  $DATA/$SDATE/pert$i
    echo >    $DATA/$SDATE/pert$i/infile_new
    #sed -n ${i}p params > job${i}/para

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
    
    #make -f $makefile -j $njobs
    make -f foomakefile2 -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
exit 1
