#!/bin/bash
#
# Initialize paths, calculate resource availability, do
# corrections based on whether to send everything as bulk
# or not to the jobqueue, modify namelists.
#
set -e
printf "\n2) Initializing OpenIFS ensemble $EXPL...\n"


# --------------------------------------------------------------
# INITIALIZE STRUCTURE
# --------------------------------------------------------------

# Make dirs
for item in $REQUIRE_DIRS; do
    test -d ${!item} || mkdir ${!item}
done

# Copy scripts
#
for item in $REQUIRE_ITEMS; do
 cp -f scripts/$item $SCRI/.
done

# Copy sources
#
for item in ${MODEL}_exp.$NAME ${MODEL}_env.$HOST; do
    cp -f sources/$item $SRC/.
done


# --------------------------------------------------------------
# RESOURCE ALLOCATION
# --------------------------------------------------------------
source scripts/general_resource_allocation

printf "   *************************************************************\n"
printf "   OpenEPS will reserve $totncpus cores on $NNODES node(s) for $reservation minutes!\n"
printf "   $parallels parallel models will be run, each on $CPUSPERMODEL core(s)\n"
printf "   *************************************************************\n"


#--------------------------------------------------------------
# BATCH JOB SETTINGS
#--------------------------------------------------------------

# If sending the job as bulk, modify job.bash
#
sed -i -e "s/.*SBATCH -p test.*/#SBATCH -p $SQUEUE/g"     $SCRI/job.bash
sed -i -e "s/.*SBATCH -J test.*/#SBATCH -J $EXPS/g"     $SCRI/job.bash
sed -i -e "s/.*SBATCH -t 5.*/#SBATCH -t $reservation/g" $SCRI/job.bash
sed -i -e "s/.*SBATCH -N 2.*/#SBATCH -N $NNODES/g"      $SCRI/job.bash
sed -i -e "s/per-node=16/per-node=$cpuspernode/g"       $SCRI/job.bash


#--------------------------------------------------------------
# Modify run namelist
#--------------------------------------------------------------

# Modify number of cores, timestepping, select output variables, etc.
#
source scripts/oifs_namelist_gen

# Write namelist part that will replace default values
#
source scripts/run/exp.namelistfc_t$RES.bash

#--------------------------------------------------------------

# Modify and compile fortran files
#
#sed -i -e "s/\:\:lon=320/\:\:lon=$lon/g"      $SCRI/calc_cost_en.f90
#sed -i -e "s/\:\:lat=160/\:\:lat=$lat/g"      $SCRI/calc_cost_en.f90
#sed -i -e "s/\:\:levmax=31/\:\:levmax=$lev/g" $SCRI/calc_cost_en.f90
#sed -i -e "s/ntime=40/ntime=/g" $SCRI/calc_cost_en.f90
#sed -i -e "s/ntime2=20/ntime2=/g" $SCRI/calc_cost_en.f90
#ftn 

# Modify post process
#
#cp -f scripts/postpro/testi.f90          $SCRI/.

#sed -i -e "s/lon=768/lon=$lon/g" $SCRI/testi.f90
#sed -i -e "s/lat=384/lat=$lat/g" $SCRI/testi.f90
#sed -i -e "s/lev=21/lev=$LEV/g"  $SCRI/testi.f90


# TEMP INIT
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

printf "   ...done!\n\n"
