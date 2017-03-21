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

# Initialize
#
source scripts/${MODEL}_init.bash

# Launch batch job
#
cd $WORK
echo 
echo "Submitting job..."
#sbatch scripts/job.bash 
bash scripts/job.bash &
echo "...done! Launcher exiting..."
echo
exit
