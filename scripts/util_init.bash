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
    test -d ${!item} || mkdir -p ${!item}
done

# Copy scripts
#
for item in $REQUIRE_ITEMS; do
 cp -f scripts/$MODEL/$item $SCRI/.
done

# Copy sources
#
for item in ${MODEL}/exp.$NAME ${MODEL}/env.$HOST; do
    cp -f configs/$item $SRC/.
done


# --------------------------------------------------------------
# RESOURCE ALLOCATION
# --------------------------------------------------------------
source scripts/util_resource_alloc.bash

printf "   *************************************************************\n"
printf "   OpenEPS will reserve $totncpus cores on $NNODES node(s) for $reservation minutes!\n"
printf "   $parallels parallel models will be run, each on $CPUSPERMODEL core(s)\n"
printf "   *************************************************************\n"


#--------------------------------------------------------------
# BATCH JOB SETTINGS
#--------------------------------------------------------------
# If sending the job as bulk, modify job.bash
#
if [ ! -z $SEND_AS_SINGLEJOB ] || [ ! -z $SEND_AS_MULTIJOB] ; then
    . scripts/util_batchjob.bash
fi
	
#--------------------------------------------------------------
# MODIFY RUN NAMELIST
#--------------------------------------------------------------
# Modify number of cores, timestepping, select output variables,
# identify ens members, set stochastic physics, etc.
#
for imem in $(seq 0 $ENS); do
    for item in $REQUIRE_NAMEL; do
	. scripts/$MODEL/$item
    done
done


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
