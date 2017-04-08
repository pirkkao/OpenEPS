#!/bin/bash

# Get process id
nid=$(pwd | grep -o -P 'pert.{0,5}' | sed -e 's/job//g')

# Log
date | echo `exec cut -b13-21` runmodel ${nid} >> $WORK/master.log

# Name nid=1 control run and other jobs pert$nid-1 
# Also, give nid three digits (clearer for job organization) 
#
echo $nid
if [ $nid -eq 0 ]; then
 name=ctrl
elif [ $nid -lt 10 ]; then
 name=pert00$nid
elif [ $nid -lt 100 ]; then
    name=pert0$nid
else
    name=pert$nid
fi
name=ctrl

rm -f ICM*+00*

#ln -sf ${EXP_DATA}/${name}_ICMCL${EXPS}INIT  ICMCL${EXPS}INIT
#ln -sf ${EXP_DATA}/${name}_ICMGG${EXPS}INIT  ICMGG${EXPS}INIT
#ln -sf ${EXP_DATA}/${name}_ICMGG${EXPS}INIUA ICMGG${EXPS}INIUA
#ln -sf ${EXP_DATA}/${name}_ICMSH${EXPS}INIT  ICMSH${EXPS}INIT
ln -sf /home/ollin/projects/OIFS/oifs38r1v04/t21test2/ICMGGepc8INIT  ICMGG${EXPS}INIT
ln -sf /home/ollin/projects/OIFS/oifs38r1v04/t21test2/ICMGGepc8INIUA ICMGG${EXPS}INIUA
ln -sf /home/ollin/projects/OIFS/oifs38r1v04/t21test2/ICMSHepc8INIT  ICMSH${EXPS}INIT
ln -sf /home/ollin/projects/OIFS/oifs38r1v04/t21test2/ifsdata/ .

ln -sf ${IFSDATA}/climatology ./ifsdata
ln -sf ${IFSDATA}/rtables
if [ $RES -eq 21 ]; then
    ln -sf ${IFSDATA}/38r1/climate/${RES}_full
else
    ln -sf ${IFSDATA}/38r1/climate/${RES}l_2
fi

cp -f $SCRI/${EXPS}.namelist fort.4
#cp -f /home/ollin/projects/OIFS/oifs38r1v04/t21test2/fort.4 .
