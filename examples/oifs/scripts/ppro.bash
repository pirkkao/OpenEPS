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
    $GRIBTOOLS/grib_set -s edition=1 ICMSH${EXPS}+00${step} temp1.grb1
    test -e ICMGG${EXPS}+00${step} && $GRIBTOOLS/grib_set -s edition=1 ICMGG${EXPS}+00${step} temp2.grb1
    test -e ICMUA${EXPS}+00${step} && $GRIBTOOLS/grib_set -s edition=1 ICMUA${EXPS}+00${step} temp3.grb1

    # Select pressure and surface level variables
    cdo -selzaxis,pressure         temp1.grb1 temp1.grb
    test -e temp2.grb1 && cdo -selzaxis,pressure,surface temp2.grb1 temp2.grb
    test -e temp3.grb1 && cdo -selzaxis,pressure temp3.grb1 temp3.grb
    
    # Do a spectral transform to gg
    if [ $RES -eq 21 ]; then
	cdo -sp2gp  temp1.grb temp_gg.grb
    else
	cdo -sp2gpl temp1.grb temp_gg.grb
    fi

    # Transform GG to regular gaussian
    test -e temp2.grb && cdo -R copy temp2.grb temp2_rg.grb
    test -e temp3.grb && cdo -R copy temp3.grb temp3_rg.grb

    # Merge
    mergefiles="temp_gg.grb "
    test -e temp2_rg.grb && mergefiles="$mergefiles temp2_rg.grb"
    test -e temp3_rg.grb && mergefiles="$mergefiles temp3_rg.grb"

    cdo -merge $mergefiles PP_${EXPS}+00${step}

    rm -f temp*.grb temp*.grb1
done
