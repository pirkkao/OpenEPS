#!/bin/bash

# Post-processing script
# REQUIRES CDO

steps=${1:-"0000"}

# Get process id
nid=$(pwd | grep -o -P "$SUBDIR_NAME.{0,5}" | sed -e "s/$SUBDIR_NAME//g")

# Log
echo `date +%H:%M:%S` post-pro $SUBDIR_NAME${nid} >> $WORK/master.log

for step in $steps; do
    # convert to GRIB1
    $GRIBTOOLS/grib_set -s edition=1 ICMSH${EXPS}+00${step} temp.grb1

    # Select pressure level variables t and z
    cdo -selzaxis,1 -selvar,var130,var129 temp.grb1 temp.grb
    
    # Do a spectral transform to gg
    if [ $RES -eq 21 ]; then
	cdo -sp2gp  temp.grb PP_${EXPS}+00${step}
    else
	cdo -sp2gpl temp.grb PP_${EXPS}+00${step}
    fi

    rm -f temp.grb temp.grb1
done
