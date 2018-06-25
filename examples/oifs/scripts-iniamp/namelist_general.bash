#!/bin/bash
#
# Modify run namelist
#

# Determine lat/lon/lev, length of time step and output interval
#
if [ $RES -eq 639 ]; then
    lon=1280
    lat=640
    lev=91
    tim=900.0
elif [ $RES -eq 511 ]; then
    lon=1024
    lat=512
    lev=91
    tim=900.0
elif [ $RES -eq 399 ]; then
    lon=800
    lat=400
    lev=91
    tim=1200.0
elif [ $RES -eq 319 ]; then
    lon=640
    lat=320
    lev=91
    tim=1200.0
elif [ $RES -eq 255 ]; then
    lon=512
    lat=256
    lev=91
    tim=2700.0
elif [ $RES -eq 159 ]; then
    lon=320
    lat=160
    lev=91
    tim=3600.0
elif [ $RES -eq 21 ]; then
    lon=64
    lat=32
    lev=19
    tim=1800.0
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
TSTEP=$tim

#NAMFPG  - Change resolution
LEV=$lev
NFPMAX=$RES

#NAMCT0  - Change experiment name, run length and output time interval
CNMEXP=$EXPS
NSTOP=$FCLEN
NFRPOS=$NFRPOS
NFRHIS=$NFRHIS
NPOSTS=0
NHISTS=0
 
#NAMFPC  - Change output fields
#
# Model level variables, their count and model levels
if [ ! -z $varsm ]; then
    MFP3DFS="MFP3DFS(1:)=${VARSM// /,}," # Replace spaces with commas
    NFP3DFS="NFP3DFS=${#varsm[@]},"  # Number of elements in the array
    NRFP3S="NRFP3S=${LEVSM// /,},"
fi

# Pressure level variables,their count and pressure levels (in Pa)
if [ ! -z $varsp ]; then
    MFP3DFP="MFP3DFP=${VARSP// /,},"
    NFP3DFP="NFP3DFP=${#varsp[@]},"
    RFP3P="RFP3P(1:)=${LEVSP// /,},"
fi

# Surface level dynamic variables and their count
if [ ! -z $varss ]; then
    MFP2DF="MFP2DF=${VARSS// /,},"
    NFP2DF="NFP2DF=${#varss[@]},"
fi

# Surface variables and their count
if [ ! -z $varpp ]; then
    MFPPHY="MFPPHY(1:)=${VARPP// /,},"
    NFPPHY="NFPPHY=${#varpp[@]},"
fi

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
if [ $LSPPT == "true" ] && [ $imem -gt 0 ]; then

    # Change SPPT amplitude, apply the same multiplication across
    # all scales (original: SDEV_SDT=0.52,0.18,0.06,)
    if [ ! -z $LSPPT_AMPLITUDE ]; then
	sdev1=$(echo "scale=4; 0.52 * $LSPPT_AMPLITUDE" | bc -l)
	sdev2=$(echo "scale=4; 0.18 * $LSPPT_AMPLITUDE" | bc -l)
	sdev3=$(echo "scale=4; 0.06 * $LSPPT_AMPLITUDE" | bc -l)
    else
	sdev1=0.52
	sdev2=0.18
	sdev3=0.06
    fi

    NAMSPSDT="
    &NAMSPSDT
      LSPSDT=true,
      NSCALES_SDT=3,
      SDEV_SDT=$sdev1,$sdev2,$sdev3,
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
if [ $LSKEB == "true" ] && [ $imem -gt 0 ]; then
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

# Add parameter value controls if TRUE
if [ ! -z $LPAR ] && [ $LPAR == "true" ] && [ $imem -gt 0 ]; then
    NAMCUMF="
    &NAMCUMF
      ENTSHALP=2.0,
    /"

else
    NAMCUMF=""
fi
