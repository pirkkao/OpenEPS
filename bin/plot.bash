#!/bin/bash
#
# Bash interface to a simple 2D model field plotting.
# Default plotting includes control with ensemble mean and
# ensmemble mean with ensemble spread.
#
# Load the needed python libraries and call python program
# 

module load geoconda

# 1st date
python3 plot_main.py 2017080100

evince quick_look_2017080100.pdf &

# 2nd date 
if [ -d data/2017080112 ]; then
  python3 plot_main.py 2017080112

  evince quick_look_2017080112.pdf &
fi
