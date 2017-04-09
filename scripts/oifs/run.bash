#!/bin/bash

# Get log entry
mode=${1:-"start"}

# Get process id
nid=$(pwd | grep -o -P 'pert.{0,5}' | sed -e 's/pert//g')

echo `date +%H:%M:%S` runmodel pert${nid} $mode >> $WORK/master.log

# pert000 is ctrl
if [ $nid -eq 0 ]; then
    name=ctrl
else
    name=pert$nid
fi


if [ $mode == "start" ] && [ ! -z $SEND_AS_MULTIJOB ]; then
if [ $SEND_AS_MULTIJOB == "true" ]; then
    $parallel $CPUS_PER_MODEL -d 1 -e GRIB_SAMPLES_PATH=$GRIB_SAMPLES_PATH \
    -e OMP_NUM_THREADS=1 $MODEL_EXE -v ecmwf -e ${exp_name} -f t$FCLEN
fi
fi

