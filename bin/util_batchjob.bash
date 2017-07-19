#!/bin/bash

# If set, modify main.bash
if [ $SEND_AS_SINGLEJOB == "true" ]; then
    # Go through all variables named lineN, where N: 1..integer
    linenum=1
    while [ 1 ]; do
	eval line=( \${line$linenum} )
	if [ ! -z $line ]; then
	    #echo "filled" ${line[@]}
	    line="${line[@]}"
	    sed -i -e "$((linenum+1))s;$;${line}\n;" $WORK/main.bash
	    linenum=$(( linenum+1 ))
	else
	    #echo "empty" ${line[@]}
	    break
	fi
    done

# Else, modify model run
elif [ $SEND_AS_MULTIJOB == "true" ]; then
    # Go through all variables named lineN, where N: 1..integer
    linenum=1
    while [ 1 ]; do
	eval line=( \${line$linenum} )
	if [ ! -z $line ]; then
	    #echo "filled" ${line[@]}
	    line="${line[@]}"
	    sed -i -e "$((linenum+1))s;$;${line}\n;" $SCRI/run.bash
	    linenum=$(( linenum+1 ))
	else
	    #echo "empty" ${line[@]}
	    break
	fi
    done
fi
