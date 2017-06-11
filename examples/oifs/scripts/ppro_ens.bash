#!/bin/bash

# Post-processing script
# REQUIRES CDO

steps=${1:-"0000"}

# Log
echo `date +%H:%M:%S` post-pro "ens   " >> $WORK/master.log

# Makes only sense for ENS > 1
if [ $ENS -gt 1 ]; then
    for step in $steps; do
	# Constuct namelist
	enslist=""
	for imem in $(seq 1 $ENS); do
	    imem=$(printf "%03d" $imem)
	    enslist="$enslist pert${imem}/PP_${EXPS}+00$step "
	done

	# Calculate ensemble mean
	cdo -ensmean ${enslist} PP_ensmean+00$step
	
	# Calculate ensemble stdev
	cdo -ensstd ${enslist} PP_ensstd+00$step

	# Copy the ctrl pp to date-folder
	cp -f pert000/PP_${EXPS}+00${step} PP_ctrl+00$step
    done
fi
