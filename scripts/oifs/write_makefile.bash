#!/bin/bash

date=${1:-""}
nextdate="../$ndate/"

source $SCRI/util_tools.bash

# KEEP ALL FILES
printf "%s\n"    ".SECONDARY :"

# GOALS
printf "%s\n"    ".PHONY : all"
printf "%s\n"    "all : $date$TARGET_1"
printf "%s%s\n"  "$date$TARGET_1 : $(all_members 0 $ENS $TARGET_2 $date)" \
                                  "$(all_members 0 $ENS $TARGET_3 $nextdate)"
printf "\t%s\n\n" "$RULE_1"

# TARGET 2
for ((imem=0;imem<=ENS;imem++)); do
    printf "%s\n"   "$(one_member $imem $TARGET_2 $NEEDED_2 $date)"
    printf "\t%s\n" "$RULE_2"
done
printf "\n"

# TARGET 3
for ((imem=0;imem<=ENS;imem++)); do
    printf "%s\n"   "$(one_member $imem $TARGET_3 $NEEDED_3 $nextdate $date)" 
    printf "\t%s\n" "$RULE_3"
done
printf "\n"

# TARGET 4
for ((imem=0;imem<=ENS;imem++)); do
    printf "%s\n"   "$(one_member${EXTRA_4} $imem $TARGET_4 $NEEDED_4 $date)"
    printf "\t%s\n" "$RULE_4"
done
printf "\n"

# TARGET 5
for ((imem=0;imem<=ENS;imem++)); do
    printf "%s\n"   "$(one_member $imem $TARGET_5 $NEEDED_5 $date)"
    printf "\t%s\n" "$RULE_5"
done
printf "\n"

# TARGET 6
if [ ! -z $TARGET_6 ]; then
    for ((imem=0;imem<=ENS;imem++)); do
	printf "%s\n"   "$(one_member $imem $TARGET_6 $NEEDED_6 $date)"
	printf "\t%s\n" "$RULE_6"
    done
    printf "\n"
fi
