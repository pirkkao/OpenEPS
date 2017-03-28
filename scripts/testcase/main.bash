#!/bin/bash

#
# A script to run an ensemble of models for N-dates.
# Optionally an iterative parameter search type algorithm can be enabled.
#

# Stop execution in case of error. More specifically, stop if the last
# command of the line does not return zero.
set -e
printf "\n\n4) Now in main.bash\n"


# Set program source, work directories and available resources
for f in sources/*; do source $f; done


# Dummy routine for generating initial input
#
mkdir -p $DATA/$SDATE

for i in $(seq 0 $ENS); do
    # Add 1-2 leading zeros if ens member < 100
    if [ $i -lt 10 ]; then i=00$i; elif [ $i -lt 100 ]; then i=0$i; fi
    mkdir -p  $DATA/$SDATE/pert$i
    echo >    $DATA/$SDATE/pert$i/infile_new
done


# Print the makefile in explicit form
#
makemake () {
    
    printf ".PHONY: all\n\n"
    eval temp=$TARGET_A0 # cdate wont evaluate otherwise...
    printf "all: %s\n\n"  "${temp}"
    printf "%s : %s\n"    "${temp}"   "${ALL_TARGETS_A}"
    printf "\t%s \n\n"    "${RULE_A}" 
    
    for itarget in $(echo {B..E}); do
	eval ctarget='${'TARGET_${itarget}'0}'
	eval dtarget='${'TARGET_${itarget}'1}'
	eval etarget='${'RULE_${itarget}'}'
	
	if [ $itarget == "C" ]; then
	    ddate=$ndate
	else
	    ddate=$cdate
	fi
	
	printf "# Case %s = %s : %s\n" "$itarget" "$ctarget" "$dtarget"
	
	for i in $(seq 0 $ENS); do
	    if [ $i -lt 10 ]; then i=00$i; elif [ $i -lt 100 ]; then i=0$i; fi
	    if [ ! -z $dtarget ]; then
		printf "%s/pert%s/%s : %s/pert%s/%s\n" "$ddate" $i \
		       "${ctarget##*/}" "$cdate" $i "${dtarget##*/}"
	    else
		printf "%s/pert%s/%s : \n" "$cdate" $i "${ctarget##*/}"
	    fi
	done
	printf "\t%s\n\n" "$etarget"
    done
}

# Targets and rules for makefile
#
# TARGET_A0        - the final target that make will try to reach
# TARGET_A1:N      - dependencies of TARGET_A
# ALL_TARGETS_A1:N - dependencies as a complete list
#
# TARGET_B0        - what TARGET_B will produce
# TARGET_B1:N      - dependencies of TARGET_B
#
# TARGET_C0        - what TARGET_C will produce
# TARGET_C1:N      - dependencies of TARGET_C
#
# TARGET_D0        - what TARGET_D will produce
# TARGET_D1:N      - dependencies of TARGET_D
#
# TARGET_E0        - what TARGET_E will produce
# TARGET_E1:N      - dependencies of TARGET_E
#
# RULE_A    - commands to execute once TARGET_A1:N are available
# RULE_B    - commands to execute once TARGET_B1:N are available
# RULE_C    - commands to execute once TARGET_C1:N are available
# RULE_D    - commands to execute once TARGET_D1:N are available
# RULE_E    - commands to execute once TARGET_E1:N are available

TARGET_E0=%/infile
TARGET_E1=""
RULE_E='cd $(dir $@) ;  cp -f infile_new infile'
export TARGET_E0 TARGET_E1 RULE_E

TARGET_D0=%/outfile
TARGET_D1=%/infile
RULE_D='cd $(dir $@) ; echo > outfile'
export TARGET_D0 TARGET_D1 RULE_D

TARGET_C0=\${ndate}/%/infile_new
TARGET_C1=\${cdate}/%/outfile
RULE_C='mkdir -p $(dir $@); cd $(dir $@); echo > infile_new'
export TARGET_C0 TARGET_C1 RULE_C

TARGET_B0=%/ppfile
TARGET_B1=%/outfile
RULE_B='cd $(dir $@) ; echo > ppfile'
export TARGET_B0 TARGET_B1 RULE_B

TARGET_A0=\${cdate}/date_finished
TARGET_A1=ppfile
TARGET_A2=infile_new
RULE_A='echo > ${cdate}/date_finished'
export TARGET_A0 ALL_TARGETS_A RULE_A

# Set programs
makefile=${SCRI}/makefile


cd $DATA
export cdate ndate
cdate=$SDATE
while [ $cdate -le $EDATE ]; do
    # Log
    echo                                >> $WORK/master.log
    echo "Running ens for $cdate"       >> $WORK/master.log
    date | echo `exec cut -b13-21` init >> $WORK/master.log
    echo "   Processing date $cdate"
    
    # Define next date
    ndate=`exec $SCRI/./mandtg $cdate + $DSTEP`

    # List all perturbation folders, trim and turn into an array
    flist=$(ls -d $cdate/pert*)
    flist=${flist//[$'\t\r\n']/ }; flist=( $flist )
    flist_nextdate=${flist[@]//${cdate}\//${ndate}\/}; flist_nextdate=( $flist_nextdate )

    # Create list of items for ALL_TARGETS_A
    # (add TARGET_A1 after flist elements and TARGET_A2 after flist_nextdate elements)
    ALL_TARGETS_A1=${flist[@]/%//${TARGET_A1}}
    ALL_TARGETS_A2=${flist_nextdate[@]/%//${TARGET_A2}}
    ALL_TARGETS_A="$ALL_TARGETS_A1 $ALL_TARGETS_A2"

    makemake > ${cdate}/foomakefile
    make -f $makefile -j $PARALLELS_IN_NODE
    
    cdate=$ndate
done
    
set +e

printf "\n\nOpenEPS finished \n"
