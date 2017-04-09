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
elif [ $RES -eq 255 ]; then
    lon=768
    lat=384
    lev=91
    tim=2700.0
elif [ $RES -eq 21 ]; then
    lon=64
    lat=32
    lev=19
    tim=600.0
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

#NAMCT0  - Change experiment name, run length and output time interval
CNMEXP=$EXPS
NSTOP=$FCLEN
NFRPOS=$NFRPOS
NFRHIS=$NFRHIS
NPOSTS=0
NHISTS=0
 
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


# Add grib identification information
NAMGRIB="
&NAMGRIB
   NLOCGRB=30,
   NLEG=1,
   NENSFNB=$imem,
   NTOTENS=$(( ENS + 1 )),
   NREFERENCE=0,
/"

if [ $imem -eq 0 ]; then
    CTYPE="cf"
else
    CTYPE="pf"
fi

# Add SPPT switches if TRUE
if [ $LSPPT == "true" ]; then
    NAMSPSDT="
    &NAMSPSDT
      LSPSDT=true,
      NSCALES_SDT=3,
      SDEV_SDT=0.52,0.18,0.06,
      TAU_SDT=2.16e4,2.592e5,2.592e6,
      XLCOR_SDT=500.e3,1000.e3,2000.e3,
    /"
else
    NAMSPSDT="
    &NAMSPSDT
      LSPSDT=false,
    /" 
fi

# Add SKEB switches if TRUE
if [ $LSKEB == "true" ]; then
    NAMSTOPH="
    &NAMSTOPH
      LSTOPH_SPBS=true,
      RATIO_BACKSCAT=0.36,
    /"
else
    NAMSTOPH="
    &NAMSTOPH
      LSTOPH_SPBS=false,
    /"
fi    
