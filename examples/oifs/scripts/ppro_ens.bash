#!/bin/bash

# Post-processing script
# REQUIRES CDO

steps=${1:-"0000"}

# Log
echo `date +%H:%M:%S` post-pro "ens   " >> $WORK/master.log

# Makes only sense for ENS > 1
if [ $ENS -gt 1 ]; then
    steplist=""
    for step in $steps; do
	# Constuct namelist
	enslist=""
	for imem in $(seq 1 $ENS); do
	    imem=$(printf "%03d" $imem)
	    enslist="$enslist $SUBDIR_NAME${imem}/PP_${EXPS}+00$step "
	done
	
	# Calculate ensemble mean
	cdo -ensmean ${enslist} PP_ensmean+00$step
	
	# Calculate ensemble stdev
	cdo -ensstd ${enslist} PP_ensstd+00$step

	# Copy the ctrl pp to date-folder
	cp -f ${SUBDIR_NAME}000/PP_${EXPS}+00${step} PP_ctrl+00$step

	steplist="$steplist $step"
    done

    # Merge steps and create a nc-file
    cdo -mergetime PP_ensmean+00* PP_ensmean
    cdo -mergetime PP_ensstd+00* PP_ensstd
    cdo -mergetime PP_ctrl+00* PP_ctrl

    cdo -f nc copy PP_ensmean PP_ensmean.nc
    cdo -f nc copy PP_ensstd  PP_ensstd.nc
    cdo -f nc copy PP_ctrl    PP_ctrl.nc

    rm -f PP_ensmean PP_ensstd PP_ctrl 
fi
