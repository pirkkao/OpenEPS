#!/bin/bash

# Get process id
nid=$(echo $@ | sed -e "s/\/job/ /g" -e 's/\/input/ /g' | cut -d " " -f 2 | tr -d ' ')
echo $@
sleep 5
echo "$(hostname): $(pwd | grep -o 'job[0-9]\+')-output-$(pwd | grep -o '[0-9]\{8\}' )"

date | echo `exec cut -b12-20` runmodel ${nid} >> $runs/../master.log

aprun -n 16 -d 6 -e GRIB_SAMPLES_PATH=$grib_samples -e OMP_NUM_THREADS=6 \
    $oifs_exe -v ecmwf -e ${exp_name} -f t240
