#!/bin/bash

# Get log entry
mode=${1:-"start"}

# Get process id
nid=$(pwd | grep -o -P "$SUBDIR_NAME.{0,5}" | sed -e "s/$SUBDIR_NAME//g")

echo `date +%H:%M:%S` runmodel $SUBDIR_NAME${nid} $mode >> $WORK/master.log

# pert000 is ctrl
if [ $nid -eq 0 ]; then
    name=ctrl
else
    name=$SUBDIR_NAME$nid
fi


if [ $mode == "start" ] && [ ! -z $SEND_AS_MULTIJOB ]; then
if [ $SEND_AS_MULTIJOB == "true" ]; then
    $parallel $CPUS_PER_MODEL -d 1 -e GRIB_SAMPLES_PATH=$GRIB_SAMPLES_PATH \
    -e OMP_NUM_THREADS=1 $MODEL_EXE -v ecmwf -e ${exp_name} -f t$FCLEN
fi
fi

# Print progress through /dev/null direct
if [ $mode == finish ] && [ $VERBOSE -eq 0 ]; then
    printf "#" > /dev/tty
fi
