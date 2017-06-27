#!/bin/bash

date=${1}
sampleonly=${2:-false}

# Log
echo `date +%H:%M:%S` pargener "ens   " >> $WORK/master.log

# Parameter perturbations
#
# Sample only, no distribution update
if [ $sampleonly != false ]; then
    echo "do stuff" > /dev/null
fi

# Set up an awk function for real number calculations
rcalc() { awk "BEGIN{print $*}"; }

# Generate random parameter values for each ens member
# $RANDOM € {0 .. 32767}
# 
for imem in $(seq 1 $ENS); do
    imem=$(printf "%03d" $imem)
	    
    number=$RANDOM
    number=$(rcalc $number/32767.-0.5)
    # Scale and add to default value (ENTSHALP=2.0)
    number=$(rcalc $number*0.1+2.0)

    echo $number > $DATA/$date/pert$imem/par_values

done

