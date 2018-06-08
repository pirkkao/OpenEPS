#!/bin/bash

date=${1}

# Log
echo `date +%H:%M:%S` pargener "ens   " >> $WORK/master.log

# Generate random cost func values
if [ 1 -eq 1 ]; then
# Set up an awk function for real number calculations
rcalc() { awk "BEGIN{print $*}"; }

# Generate random parameter values for each ens member
# $RANDOM € {0 .. 32767}
#
rm -f $DATA/eppes/scores.dat
for imem in $(seq 1 $ENS); do
    imem=$(printf "%03d" $imem)
	    
    number=$RANDOM
    number=$(rcalc $number/32767.-0.5)
    # Scale and add to default value (ENTSHALP=2.0)
    number=$(rcalc $number*0.1+2.0)

    echo $number >> $DATA/eppes/scores.dat
done
fi


# Parameter perturbations
#
pushd $DATA/eppes > /dev/null
cp -f sampleout.dat oldsample.dat
./eppes_routine

# Store values
for item in mu sig n w; do
    cp -f ${item}file.dat $date/.
done
cp -f sampleout.dat $date/.
mv scores.dat $date/.

popd > /dev/null

