#!/bin/bash
#
# Initialize paths, calculate resource availability, do
# corrections based on whether to send everything as bulk
# or not to the jobqueue, modify namelists.
#
set -e
printf "\n2) Initializing ${MODEL} ensemble $EXPL...\n"
if [ $VERBOSE -eq 1 ]; then
    verbose=true
else
    verbose=false
fi
printf "   Verbose = $verbose\n"
printf "   Restart = $RESTART\n\n"



# --------------------------------------------------------------
# (RE)INITIALIZE STRUCTURE
# --------------------------------------------------------------
# Remove previous structure
#
if [ $RESTART == "true" ]; then
    # Just to be super safe
    if [ "$WORK" == "/" ] || [ "$WORK" == "$HOME" ]; then
	echo "Check WORK directory path..."
	exit
    fi
    # Also only remove $WORK/data
    test ! -d $WORK/data | rm -rf $WORK/data
    rm -f $WORK/master.log
fi


# Make dirs
#
for item in $REQUIRE_DIRS; do
    test -d ${!item} || mkdir -p ${!item}
done


# Get model base folder name
#
#modelbase=$(echo $MODEL | cut -d- -f1)

# Copy scripts
#
default=""
modded=""
for item in $REQUIRE_ITEMS $REQUIRE_NAMEL; do
    if [ -f   examples/$MODEL/scripts-$SCR_MOD/$item ]; then
	cp -f examples/$MODEL/scripts-$SCR_MOD/$item $SCRI/.
	modded="$modded $item"
    else
	default="$default $item"
    fi
done

# Complete by default scripts
nonutil=""
for item in $default; do
    if [ -f   examples/$MODEL/scripts/$item ]; then
	cp    examples/$MODEL/scripts/$item $SCRI/.
	nonutil="$nonutil $item"
    elif [ -f bin/$item ]; then
	cp    bin/$item $WORK/.
    elif [ ! -z ${!item} ] && [ -f ${!item} ] ; then
	cp    ${!item} $WORK/.
    else
	printf "%s\n" "$item not found, aborting..."
	exit 1
    fi
done

printf "%s %s\n" "   Scripts requested:   $nonutil"
printf "%s \n"   "   Non-default scripts: $modded"
printf "\n"

# Copy configs
#
for item in exp.$NAME env.$HOST; do
    cp -f examples/$MODEL/configs/$item $SRC/.
done


# Set default subfolder to be "pertXXX"
if [ -z $SUBDIR_NAME ]; then
    SUBDIR_NAME=pert
fi
export SUBDIR_NAME


# --------------------------------------------------------------
# RESOURCE ALLOCATION
# --------------------------------------------------------------
source bin/util_resource_alloc.bash

printf "   *************************************************************\n"
printf "   OpenEPS will reserve $totncpus cores for $EXPTIME\n"
printf "   $parallels parallel models will be run, each on $CPUSPERMODEL core(s)\n"
printf "   *************************************************************\n"



# --------------------------------------------------------------
# BATCH JOB SETTINGS
# --------------------------------------------------------------
# If sending the job as bulk, modify job.bash
#
if [ ! -z $SEND_AS_SINGLEJOB ] || [ ! -z $SEND_AS_MULTIJOB] ; then
    . bin/util_batchjob.bash
fi



# --------------------------------------------------------------
# MODIFY RUN NAMELIST
# --------------------------------------------------------------
# Modify number of cores, timestepping, select output variables,
# identify ens members, set stochastic physics, etc.
#
for imem in $(seq 0 $ENS); do
    for item in $REQUIRE_NAMEL; do
	. $SCRI/$item
    done
done



# --------------------------------------------------------------
# GENERATE SUB-STRUCTURE
# --------------------------------------------------------------
# Generate sub-directories, input files and Makefiles for each
# individual step
#
export cdate ndate
cdate=$SDATE
    
while [ $cdate -le $EDATE ]; do
    
    for imem in $(seq 0 $ENS); do
	# Add leading zeros
	imem=$(printf "%03d" $imem)
	mkdir -p  $DATA/${DATE_DIR}$cdate/$SUBDIR_NAME$imem
    done

    # Define next date here so it can be used in makefile writing
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



# --------------------------------------------------------------
# INITIALIZE PARAMETER ESTIMATION IF TRUE
# --------------------------------------------------------------
if [ ! -z $LPAR ] && [ $LPAR == "true" ]; then
    
    cdate=$SDATE
    while [ $cdate -le $EDATE ]; do
	
	# Define next date
	if [ -e $WORK/mandtg ]; then
	    ndate=`exec $WORK/./mandtg $cdate + $DSTEP`
	else
	    ndate=$(( $cdate + $DSTEP ))
	fi
    
	# Create EPPES dir structure
	if [ ! -z $LPAR ] && [ $LPAR == "true" ]; then
	    mkdir -p $DATA/eppes/${DATE_DIR}$cdate
	fi
    
	cdate=$ndate
    done

    # Init EPPES
    if [ -f $SCRI/par_init.bash ]; then
	. $SCRI/par_init.bash $SDATE
    fi
fi



# --------------------------------------------------------------
# MODIFY POST-PROCESSING
# --------------------------------------------------------------
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
