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
echo
echo "OpenEPS" `git tag`
echo 
echo "Running an ensemble of $ENS-members for $MODEL."
echo "Start date for ensemble is $SDATE and end date $EDATE"
echo 

# Check that all vital paths/executables exist
#
source scripts/general_test

# Initialize
#
source scripts/${MODEL}_init.bash

# Launch bash/batch job
#
cd $WORK
echo 
echo "3) Submitting job..."
#sbatch scripts/job.bash 
bash scripts/job.bash &
echo " ...done! Launcher exiting..."
echo
exit 1
