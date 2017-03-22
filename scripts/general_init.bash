#!/bin/bash
#
# Initialize paths, calculate resource availability, do
# corrections based on whether to send everything as bulk
# or not to the jobqueue, modify namelists.
#
set -e
printf "\n2) Initializing ${MODEL^^} ensemble $EXPL...\n"


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
 cp -f scripts/$MODEL/$item $SCRI/.
done

# Copy sources
#
for item in ${MODEL}_exp.$NAME ${MODEL}_env.$HOST; do
    cp -f sources/$item $SRC/.
done


# --------------------------------------------------------------
# RESOURCE ALLOCATION
# --------------------------------------------------------------
source scripts/general_resource_alloc.bash

printf "   *************************************************************\n"
printf "   OpenEPS will reserve $totncpus cores on $NNODES node(s) for $reservation minutes!\n"
printf "   $parallels parallel models will be run, each on $CPUSPERMODEL core(s)\n"
printf "   *************************************************************\n"


#--------------------------------------------------------------
# BATCH JOB SETTINGS
#--------------------------------------------------------------
# If sending the job as bulk, modify job.bash
#
sed -i -e "s/.*SBATCH -p test.*/#SBATCH -p $SQUEUE/g"   $SCRI/main.bash
sed -i -e "s/.*SBATCH -J test.*/#SBATCH -J $EXPS/g"     $SCRI/main.bash
sed -i -e "s/.*SBATCH -t 5.*/#SBATCH -t $reservation/g" $SCRI/main.bash
sed -i -e "s/.*SBATCH -N 2.*/#SBATCH -N $NNODES/g"      $SCRI/main.bash
sed -i -e "s/per-node=16/per-node=$cpuspernode/g"       $SCRI/main.bash


#--------------------------------------------------------------
# MODIFY RUN NAMELIST
#--------------------------------------------------------------
# Modify number of cores, timestepping, select output variables, etc.
#
source scripts/$MODEL/namelist_general.bash

# Write namelist part that will replace default values
#
source scripts/$MODEL/namelist_t$RES.bash


#--------------------------------------------------------------
# MODIFY POST-PROCESSING
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

printf "   ...done!\n\n"
