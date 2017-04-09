#!/bin/bash
#
# Targets and rules for makefile
#
# TARGET_1   - the final target that make will try to reach
# NEEDED_1   - dependencies of TARGET_1
# RULE_1     - 
#
# TARGET_2   - what TARGET_2 will produce
# NEEDED_2   - dependencies of TARGET_2
#
# TARGET_3   - what TARGET_3 will produce
# NEEDED_3   - dependencies of TARGET_3
#
# TARGET_4   - what TARGET_4 will produce
# NEEDED_4   - dependencies of TARGET_4
#
# TARGET_5   - what TARGET_5 will produce
# NEEDED_5   - dependencies of TARGET_5
#
# RULE_1    - commands to execute once NEEDED_1 are available
# RULE_2    - commands to execute once NEEDED_2 are available
# RULE_3    - commands to execute once NEEDED_3 are available
# RULE_4    - commands to execute once NEEDED_4 are available
# RULE_5    - commands to execute once NEEDED_5 are available

TARGET_5=infile
NEEDED_5=""
# First part should not be evaluated, second should
RULE_5=$(printf "%s%s" 'cd $(dir $@) ;' "$serial ${SCRI}/link.bash")
export TARGET_5 NEEDED_5 RULE_5

TARGET_4=oufile
NEEDED_4=$TARGET_5
# First part should not be evaluated, second should
RULE_4=$(printf "%s%s" 'cd $(dir $@) ;' "$serial ${SCRI}/run.bash ; $parallel $MODEL_EXE -e $EXPS ; $serial ${SCRI}/run.bash finish")
export TARGET_4 NEEDED_4 RULE_4

TARGET_3=infile_new
NEEDED_3=$TARGET_4
RULE_3=$(printf "%s%s%s" 'mkdir -p $(dir $@); cd $(dir $@); ' "$serial ${SCRI}/link.bash $ndate" '; echo > infile_new')
export TARGET_3 NEEDED_3 RULE_3

TARGET_2=ppfile
NEEDED_2=$TARGET_4
RULE_2='cd $(dir $@) ; echo > ppfile'
export TARGET_2 NEEDED_2 RULE_2

TARGET_1=date_finished
RULE_1='echo > date_finished'
export TARGET_1 RULE_1 
