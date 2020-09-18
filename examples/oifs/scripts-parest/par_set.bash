#!/bin/bash

# Get process id 
nid=$(pwd | grep -o -P "$SUBDIR_NAME.{0,5}" | sed -e "s/$SUBDIR_NAME//g")

# Log
echo `date +%H:%M:%S` parwrite $SUBDIR_NAME${nid} >> $WORK/master.log

# Parameter perturbations
#
if [ $nid -gt 0 ]; then
    #read par1 < par_values
    par1=$(sed "${nid}q;d" $DATA/eppes/sampleout.dat)
    par1=$(echo $par1 | awk '{print($1)}')
    
    echo "Using par1 value $par1" > parfile

    # Write new parameter values to namelist here
    sed -i -e "s#ENTSHALP=2.0,#ENTSHALP=$par1,#g" fort.4
else
    echo "Ctrl run" > parfile

    # Delete the line from ctrl
    sed -i -e "s#ENTSHALP=2.0,##g" fort.4
fi


