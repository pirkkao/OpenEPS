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
if [ $OIFSv != "43r3v1" ]; then
    ln -sf ${IFSDATA}/rtables rtables
    ln -sf ${IFSDATA}/vtables vtables
    ln -sf ${IFSDATA}/climatology/ifsdata .

    if [ $RES -eq 21 ]; then
	ln -sf ${IFSDATA}/38r1/climate/${RES}_full
    else
	ln -sf ${IFSDATA}/38r1/climate/${RES}l_2
    fi

else
    ln -sf ${IFSDATA}/43r3/rtables
    ln -sf ${IFSDATA}/43r3/vtables
    ln -sf ${IFSDATA}/43r3/ifsdata

    ln -sf ${IFSDATA}/43r3/climate.v015/${RES}l_2
fi

# Wave model
if  [ ! -z $WAM ] && [ $WAM -eq 1 ]; then

    # WAM date specific
    ln -sf ${IFSDATA}/t${RES}/$date/cdwavein .
    ln -sf ${IFSDATA}/t${RES}/$date/sfcwindin .
    ln -sf ${IFSDATA}/t${RES}/$date/specwavein .
    ln -sf ${IFSDATA}/t${RES}/$date/uwavein .

    # WAM general
    if [ $OIFSv != "43r3v1" ]; then
	wamver=40r1
    else
	wamver=43r3
    fi

    ln -sf ${IFSDATA}/t${RES}/$wamver/wam_grid_tables .
    ln -sf ${IFSDATA}/t${RES}/$wamver/wam_subgrid_0 .
    ln -sf ${IFSDATA}/t${RES}/$wamver/wam_subgrid_1 .
    ln -sf ${IFSDATA}/t${RES}/$wamver/wam_subgrid_2 .

    # Copy namelist and modify date
    cp ${IFSDATA}/t${RES}/$wamver/wam_namelist_example_tl$RES wam_namelist

    sed -i -e "s#CBPLTDT  =\"20161201000000\",#CBPLTDT  =\"${date}0000\",#g" wam_namelist
    sed -i -e "s#CDATEF   =\"20161201000000\",#CDATEF   =\"${date}0000\",#g" wam_namelist
    sed -i -e "s#CDATECURA=\"20161201000000\",#CDATECURA=\"${date}0000\",#g" wam_namelist
fi
