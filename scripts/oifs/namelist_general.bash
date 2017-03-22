#!/bin/bash
#
# Modify run namelist
#

# Determine lat/lon/lev, length of time step and output interval
#
if [ $RES -eq 639 ]; then
    lon=768
    lat=384
    lev=91
    tim=900.0
    OUTP=24
elif [ $RES -eq 255 ]; then
    lon=768
    lat=384
    lev=91
    tim=2700.0
    OUTP=24
elif [ $RES -eq 21 ]; then
    lon=64
    lat=32
    lev=19
    tim=600.0
    OUTP=10
else
    echo "Resolution not defined!"
    exit 1
fi

# Have to do some string manipulation before writing out
varsm=( $VARSM )      # Change into an array
varsp=( $VARSP )
varss=( $VARSS )
varpp=( $VARPP )

#NAMPAR0 - Change number of processors used
NPROC=$CPUSPERMODEL

#NAMDYN  - Change model time step according to used resolution
TSTEP=${tim:-2700.0}

#NAMFPG  - Change resolution
LEV=$lev
NFPMAX=${RES:-255}

#NAMCT0  - Change experiment name and output time interval
CNMEXP=$EXPS
NFRPOS=$OUTP
NFRHIS=$OUTP

#NAMFPC  - Change output fields

# Model level variables, their count and model levels
MFP3DFS=${VARSM// /,} # Replace spaces with commas
NFP3DFS=${#varsm[@]}  # Number of elements in the array
NRFP3S=${LEVSM// /,} 

# Pressure level variables,their count and pressure levels (in Pa)
MFP3DFP=${VARSP// /,}
NFP3DFP=${#varsp[@]}
RFP3P=$LEVSP

# Surface level dynamic variables and their count
MFP2DF=${VARSS// /,}
NFP2DF=${#varss[@]}

# Surface variables and their count
MFPPHY=${VARPP// /,}
NFPPHY=${#varpp[@]}

#NAMFPD  - Change grid point variables' output resolution
NLAT=$lat
NLON=$lon
