#!/bin/bash

# Get date
date=${1:-$cdate}

# Get process id
nid=$(pwd | grep -o -P 'pert.{0,5}' | sed -e 's/pert//g')

# Log
echo `date +%H:%M:%S` link "   " pert${nid} >> $WORK/master.log

# pert000 is ctrl
if [ $nid -eq 0 ]; then
    name=ctrl
else
    name=pert$nid
fi

# Link namelist
ln -sf $SCRI/namelist.$name fort.4

# All initial states link to control until the states can be generated
name=ctrl



rm -f ICM*+00*

# Link day specific fields
if [ $RES -ne 21 ]; then # T21 does not need the climate file, also point all
                         # perts to ctrl
    ln -sf ${IFSDATA}/t${RES}/$date/ctrl_ICMCL_INIT  ICMCL${EXPS}INIT
fi
ln -sf ${IFSDATA}/t${RES}/$date/${name}_ICMGG_INIT  ICMGG${EXPS}INIT
ln -sf ${IFSDATA}/t${RES}/$date/${name}_ICMGG_INIUA ICMGG${EXPS}INIUA
ln -sf ${IFSDATA}/t${RES}/$date/${name}_ICMSH_INIT  ICMSH${EXPS}INIT

# Link climatologies
ln -sf ${IFSDATA}/climatology/ifsdata .
ln -sf ${IFSDATA}/rtables
if [ $RES -eq 21 ]; then
    ln -sf ${IFSDATA}/38r1/climate/${RES}_full
else
    ln -sf ${IFSDATA}/38r1/climate/${RES}l_2
fi

