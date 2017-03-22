#!/bin/bash
#
# Launch EPS job.
#
#
# Authors: pirkka.ollinaho@fmi.fi
#          juha.lento@csc.fi

# Run options
#
export NAME=name
export MODEL=oifs
export HOST=$(hostname | cut -c 1-5)

# Import correct settings
#
source sources/${MODEL}_exp.$NAME # Experiment specific settings
source sources/${MODEL}_env.$HOST # Environment specific settings

# Broadcast general
#
printf "\nOpenEPS `git tag`\n"
printf "\nRunning an ensemble of $ENS-members for $MODEL."
printf "\nStart date for ensemble is $SDATE and end date $EDATE\n"

# Check that all vital paths/executables exist
#
source scripts/general_test

# Initialize
#
source scripts/${MODEL}_init.bash

# Launch bash/batch job
#
cd $WORK
printf "\n3) Submitting job...\n"
#sbatch scripts/job.bash 
bash scripts/job.bash &
printf "   ...done! Launcher exiting...\n\n"

exit 1
