#!/bin/bash

# Get date
date=${1:-$cdate}

# Get process id
nid=$(pwd | grep -o -P "$SUBDIR_NAME.{0,5}" | sed -e "s/$SUBDIR_NAME//g")

# Log
echo `date +%H:%M:%S` link "   " $SUBDIR_NAME${nid} >> $WORK/master.log

# pert000 is ctrl
if [ $nid -eq 0 ]; then
    name=ctrl
else
    name=$SUBDIR_NAME$nid
fi

# Copy namelist
cp -f $SCRI/namelist.$name fort.4

# Under which alias the unperturbed ini is
ename=oifs

# Set initial perturbations off if INIPERT variable is not set
if [ -z $INIPERT ]; then
    INIPERT=0
fi

# Clean directory
rm -f ICM*+00*

# Link day specific fields
if [ $RES -ne 21 ]; then # T21 does not need the climate file
    ln -sf ${IFSDATA}/t${RES}/$date/ICMCL${ename}INIT.1  ICMCL${EXPS}INIT
fi

if [ $nid -eq 0 ] || [ $INIPERT -eq 0 ]; then
    ln -sf ${IFSDATA}/t${RES}/$date/ICMGG${ename}INIT  ICMGG${EXPS}INIT
    ln -sf ${IFSDATA}/t${RES}/$date/ggml$RES           ICMGG${EXPS}INIUA
    ln -sf ${IFSDATA}/t${RES}/$date/ICMSH${ename}INIT  ICMSH${EXPS}INIT

else
    # Pick odd initial state pertubations
    if [ ! -z $INIFAIR ] && [ $INIFAIR -eq 1 ]; then
	nid=$((10#$nid * 2 - 1)) # force into 10-base number with 10#
	nid=$(printf '%03d' $nid)
    fi

    ln -sf ${IFSDATA}/t${RES}/$date/psu_$nid  ICMGG${EXPS}INIT
    ln -sf ${IFSDATA}/t${RES}/$date/pan_$nid  ICMGG${EXPS}INIUA
    ln -sf ${IFSDATA}/t${RES}/$date/pua_$nid  ICMSH${EXPS}INIT
fi

# Link climatologies
ln -sf ${IFSDATA}/climatology/ifsdata .
ln -sf ${IFSDATA}/rtables
if [ $RES -eq 21 ]; then
    ln -sf ${IFSDATA}/38r1/climate/${RES}_full
else
    ln -sf ${IFSDATA}/38r1/climate/${RES}l_2
fi

