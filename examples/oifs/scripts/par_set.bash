#!/bin/bash

# Get process id 
nid=$(pwd | grep -o -P 'pert.{0,5}' | sed -e 's/pert//g')

# Log
echo `date +%H:%M:%S` parwrite pert${nid} >> $WORK/master.log

# Parameter perturbations
#
if [ $nid -gt 0 ]; then
    #read par1 < par_values
    par1=$(sed "${nid}q;d" $DATA/eppes/sampleout.dat)
    
    echo "Using par1 value $par1" > parfile
    # WRITE NEW PARAMETER VALUES TO namelist HERE
    sed -i -e "s#ENTSHALP=2.0#ENTSHALP=$par1#g" $SCRI/namelist.pert${nid}
else
    echo "Ctrl run" > parfile
    # EITHER WRITE BLANK VALUES TO NAMELIST OR DO NOTHING
    # &NAMCUMF
    # /
fi


