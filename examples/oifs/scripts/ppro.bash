#!/bin/bash

# Post-processing script
# REQUIRES CDO

steps=${1:-"0000"}

# Get process id
nid=$(pwd | grep -o -P "$SUBDIR_NAME.{0,5}" | sed -e "s/$SUBDIR_NAME//g")

# Log
echo `date +%H:%M:%S` post-pro $SUBDIR_NAME${nid} >> $WORK/master.log

for step in $steps; do
    # Select pressure level variables t and z
    cdo -selzaxis,1 -selvar,t,z ICMSH${EXPS}+00${step} temp.grb
    
    # Do a spectral transform to gg
    cdo -sp2gp temp.grb PP_${EXPS}+00${step}

    rm -f temp.grb
done
