#!/bin/bash
#
# Initialize paths, calculate resource availability, do
# corrections based on whether to send everything as bulk
# or not to the jobqueue, modify namelists.
#
set -e
printf "\n2) Initializing ${MODEL} ensemble $EXPL...\n"


# --------------------------------------------------------------
# INITIALIZE STRUCTURE
# --------------------------------------------------------------
# Make dirs
for item in $REQUIRE_DIRS; do
    test -d ${!item} || mkdir -p ${!item}
done

# Copy scripts
#
for item in $REQUIRE_ITEMS $REQUIRE_NAMEL; do
    if [ -f   examples/$MODEL/scripts/$item ]; then
	cp -f examples/$MODEL/scripts/$item $SCRI/.
    elif [ -f bin/$item ]; then
	cp -f bin/$item $WORK/.
    elif [ ! -z ${!item} ] && [ -f ${!item} ] ; then
	cp -f ${!item} $WORK/.
    else
	printf '\n%s\n' "Aborting, $item not found..."
	exit 1
    fi
done

# Copy configs
#
for item in exp.$NAME env.$HOST; do
    cp -f examples/$MODEL/configs/$item $SRC/.
done



# --------------------------------------------------------------
# RESOURCE ALLOCATION
# --------------------------------------------------------------
source bin/util_resource_alloc.bash

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
    . bin/util_batchjob.bash
fi



#--------------------------------------------------------------
# MODIFY RUN NAMELIST
#--------------------------------------------------------------
# Modify number of cores, timestepping, select output variables,
# identify ens members, set stochastic physics, etc.
#
for imem in $(seq 0 $ENS); do
    for item in $REQUIRE_NAMEL; do
	#. scripts/$MODEL/$item
	. $SCRI/$item
    done
done



#--------------------------------------------------------------
# Generate sub-directories, input files and Makefiles for each
# individual step
#--------------------------------------------------------------
export cdate ndate
cdate=$SDATE

# Set default subfolder to be "pertXXX"
if [ -z $SUBDIR_NAME ]; then
    SUBDIR_NAME=pert
fi
    
while [ $cdate -le $EDATE ]; do
    
    for imem in $(seq 0 $ENS); do
	# Add leading zeros
	imem=$(printf "%03d" $imem)
	mkdir -p  $DATA/${DATE_DIR}$cdate/$SUBDIR_NAME$imem
	#echo >    $DATA/$cdate/pert$imem/infile_new
    done

    if [ ! -z $LPAR ] && [ $LPAR == "true" ]; then
	mkdir -p $DATA/eppes/${DATE_DIR}$cdate
    fi

    # Define next date
    if [ -e $WORK/mandtg ]; then
	ndate=`exec $WORK/./mandtg $cdate + $DSTEP`
    else
	ndate=$(( $cdate + $DSTEP ))
    fi
    
    # Generate makefile for current date
    if [ $MODEL != lorenz95 ]; then
	. $SCRI/define_makefile  > $DATA/${DATE_DIR}$cdate/makefile_$cdate
    fi
    
    cdate=$ndate
done

if [ $MODEL == lorenz95 ]; then
    pushd $DATA > /dev/null
    cp ${DEFDIR}/eppes_init/*.dat eppes/day0
    . $SCRI/define_makefile
    popd > /dev/null
fi

# Initialize parameter estimation if TRUE
#
if [ ! -z $LPAR ] && [ $LPAR == "true" ] && [ -f $SCRI/par_init.bash ]; then
    . $SCRI/par_init.bash $SDATE
fi

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
