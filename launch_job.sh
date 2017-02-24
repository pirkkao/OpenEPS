#!/bin/bash
#
# Launch EPS job.
#
#
# Authors: pirkka.ollinaho@fmi.fi
#          juha.lento@csc.fi

# Run options
#
EXPL="testiEPS" && export EXPL   # Long exp name
EXPS="teps"     && export EXPS   # 4 letter exp name
SDATE=2013110212  && export SDATE  # Exp start date
EDATE=2013110212  && export EDATE  # Exp end   date
DSTEP=24        && export DSTEP  # Hours between ensembles

# Resolution, vertical levels, model run length (in h)
RES=21 && export RES
LEV=19  && export LEV
FCL=3   && export FCL

# Ensemble size
ENS=1 && export ENS
NNODES=2 && export NNODES

# Initialize 
#
if [ -z $WRKDIR ]; then WRKDIR=$HOME/projects/OIFS/data; fi
WORK=$WRKDIR/$EXPL && export WORK
SCRI=$WORK/scripts && export SCRI
DATA=$WORK/data    && export DATA
bash scripts/initjob.sh

# Launch batch job
#
cd $WORK
echo 
echo "Submitting job..."
#sbatch scripts/job.bash $SCRI $DATA $SDATE $EDATE $DSTEP
bash scripts/job.bash $SCRI $DATA $SDATE $EDATE $DSTEP &
#echo "sbatch scripts/job.bash $SCRI $DATA $SDATE $EDATE"
echo "...done! Launcher exiting..."
echo
exit
