#!/bin/bash
#
# Initialize paths etc.
#
#
set -e
echo
echo "2) Initializing OpenIFS ensemble $EXPL..."

# Make dirs
#
test -d $WORK || mkdir $WORK
test -d $SCRI || mkdir $SCRI
test -d $DATA || mkdir $DATA
test -d $SRC  || mkdir $SRC

# Copy run scripts
#
for item in job.bash makefile pargen model_link model_run funceval mandtg; do
 cp -f scripts/$item $SCRI/.
done
cp -f scripts/postpro/calculate_cost_function_template_en.f90 $SCRI/calc_cost_en.f90

# Copy sources
#
for item in ${MODEL}_exp.$NAME ${MODEL}_env.$HOST; do
    cp -f sources/$item $SRC/.
done

#--------------------------------------------------------------
# Resource calculations
#

# Dates
dates=1
date=$SDATE
while [ $date -lt $EDATE ]; do
    date=$(exec scripts/mandtg $date + $DSTEP)
    ((dates+=1))
done

# Define parallelism
#
totncpus=$(echo "$NNODES * $SYS_CPUSPERNODE" | bc)

# Check does a single model take more than one node
nodespermodel=1
cpus=$CPUSPERMODEL
while [ $cpus -gt $SYS_CPUSPERNODE ]; do
    cpus=$(echo "$cpus - $SYS_CPUSPERNODE" | bc)
    ((nodespermodel+=1))
done

if [ $nodespermodel -gt $NNODES ]; then
    echo "ILLEGAL RESOURCE ALLOCATION!"
    exit
fi
# Note! Parallels can run in the same node and/or in different
# nodes, need to check that no inter-node parallelism is allocated
parallels_in_node=$(echo $SYS_CPUSPERNODE / $CPUSPERMODEL | bc)
parallel_nodes=$(echo "$NNODES / $nodespermodel" | bc)
if [ $parallels_in_node -eq 0 ]; then
    parallels=$parallel_nodes
else
    parallels=$(echo "$parallels_in_node * $parallel_nodes" | bc)
fi

# Estimate time reservation
totaltime=$(echo "$TIMEFORMODEL * $ENS * $dates" | bc)
reservation=$(echo "$totaltime / $parallels" | bc)

echo "   *************************************************************"
echo "   OpenEPS will reserve $totncpus cores on $NNODES node(s) for $reservation minutes!"
echo "   $parallels parallel models will be run, each on $CPUSPERMODEL core(s)"
echo "   *************************************************************"

# Write a source file
cat <<EOF > $SRC/resources
#!/bin/bash
export PARALLELS_IN_NODE=$parallels_in_node
export PARALLEL_NODES=$parallel_nodes

EOF

#--------------------------------------------------------------



# Modify job.bash
#
sed -i -e "s/.*SBATCH -p test.*/#SBATCH -p $SQUEUE/g"     $SCRI/job.bash
sed -i -e "s/.*SBATCH -J test.*/#SBATCH -J $EXPS/g"     $SCRI/job.bash
sed -i -e "s/.*SBATCH -t 5.*/#SBATCH -t $reservation/g" $SCRI/job.bash
sed -i -e "s/.*SBATCH -N 2.*/#SBATCH -N $NNODES/g"      $SCRI/job.bash
sed -i -e "s/per-node=16/per-node=$cpuspernode/g"       $SCRI/job.bash


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
    lon=
    lat=
    lev=19
    tim=600.0
    OUTP=10
else
    echo "Resolution yet undefined!"
    exit
fi

# Modify and compile fortran files
#
#sed -i -e "s/\:\:lon=320/\:\:lon=$lon/g"      $SCRI/calc_cost_en.f90
#sed -i -e "s/\:\:lat=160/\:\:lat=$lat/g"      $SCRI/calc_cost_en.f90
#sed -i -e "s/\:\:levmax=31/\:\:levmax=$lev/g" $SCRI/calc_cost_en.f90
#sed -i -e "s/ntime=40/ntime=/g" $SCRI/calc_cost_en.f90
#sed -i -e "s/ntime2=20/ntime2=/g" $SCRI/calc_cost_en.f90
#ftn 


# Modify run namelist
#
cp -f scripts/run/exp.namelistfc        $SCRI/$EXPS.namelist

#NAMPAR0 - Change number of processors used
sed -i -e "s/NPROC=32/NPROC=$ncpus/g"   $SCRI/$EXPS.namelist

#NAMDYN  - Change model time step according to used resolution
sed -i -e "s/TSTEP=2700.0/TSTEP=$tim/g" $SCRI/$EXPS.namelist

#NAMFPG  - Change resolution
sed -i -e "s/NFPLEV=91/NFPLEV=$LEV/g"   $SCRI/$EXPS.namelist
sed -i -e "s/NFPMAX=255/NFPMAX=$RES/g"  $SCRI/$EXPS.namelist

#NAMCT0  - Change experiment name and output time interval
sed -i -e "s/CNMEXP=\"g135\"/CNMEXP=\"$EXPS\"/g" $SCRI/$EXPS.namelist
sed -i -e "s/NFRPOS=16/NFRPOS=$OUTP/g"           $SCRI/$EXPS.namelist
sed -i -e "s/NFRHIS=16/NFRHIS=$OUTP/g"           $SCRI/$EXPS.namelist

#NAMFPC  - Change output fields
# Model level variables, their count and model levels
VARSM="130,138,155,133"
COUNTM=4
LEVSM=""
sed -i -e "s/NFP3DFS=10/NFP3DFS=$COUNTM/g" $SCRI/$EXPS.namelist
sed -i -e "s/MFP3DFS(:)=130,135,138,155,3,133,246,247,248,75/MFP3DFS(:)=$VARSM/g" $SCRI/$EXPS.namelist
#sed -i -e "s/NRFP3S(:)=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91/NRFP3S(:)=$LEVSM/g" $SCRI/$EXPS.namelist

# Pressure level variables,their count and pressure levels (in Pa)
VARSP="129"
COUNTP=1
LEVSP="50000.0"
sed -i -e "s/NFP3DFP=11/NFP3DFP=$COUNTP/g" $SCRI/$EXPS.namelist
sed -i -e "s/MFP3DFP(:)=129,130,135,138,155,157,3,133,246,247,248/MFP3DFP(:)=$VARSP/g" $SCRI/$EXPS.namelist
sed -i -e "s/RFP3P(:)=100000.0,92500.0,85000.0,70000.0,50000.0,40000.0,30000.0,25000.0,20000.0,15000.0,10000.0,7000.0,5000.0,3000.0,2000.0,1000.0,700.0,500.0,300.0,200.0,100.0/RFP3P(:)=$LEVSP/g" $SCRI/$EXPS.namelist

# Surface level variables and their count
VARSS="129,152"
COUNTS=2
sed -i -e "s/NFP2DF=2/NFP2DF=$COUNTS/g"            $SCRI/$EXPS.namelist
sed -i -e "s/MFP2DF(:)=129,152/MFP2DF(:)=$VARSS/g" $SCRI/$EXPS.namelist

#NAMFPD  - Change grid point variables' output resolution
sed -i -e "s/NLAT=256/NLAT=$lat/g" $SCRI/$EXPS.namelist
sed -i -e "s/NLON=512/NLON=$lon/g" $SCRI/$EXPS.namelist

# Modify post process
#
#cp -f scripts/postpro/testi.f90          $SCRI/.

#sed -i -e "s/lon=768/lon=$lon/g" $SCRI/testi.f90
#sed -i -e "s/lat=384/lat=$lat/g" $SCRI/testi.f90
#sed -i -e "s/lev=21/lev=$LEV/g"  $SCRI/testi.f90


# TEMP INIT
# Dummy routine for generating initial input and parameter
# perturbations
#
mkdir -p $SCRI/$SDATE
mkdir -p $SCRI/$SDATE/inistates
cd $SCRI/$SDATE
cat <<EOF > params
2.5
2.6
2.7
2.4
3.2
1.2
1.0
5.1
1.4
EOF

for i in $(seq $ENS); do
 mkdir -p $SCRI/$SDATE/job$i
 echo >   $SCRI/$SDATE/job$i/input
 sed -n ${i}p params > job${i}/para

 if false; then
 # Initial states
 #
 i=$(echo "$i - 1" | bc)
 if [ $i -eq 0 ]; then
  name=ctrl
 elif [ $i -lt 10 ]; then
  name=pert00$name
 fi
 for item in GG SH; do # CL GG SH; do
  if [ $item == GG ]; then
   cp -f ${INIBASEDIR}/$SDATE/${name}_ICM${item}_INIUA $SCRI/$SDATE/inistates/${name}_ICM$item${EXPS}INIUA
  fi
  cp -f  ${INIBASEDIR}/$SDATE/${name}_ICM${item}_INIT $SCRI/$SDATE/inistates/${name}_ICM$item${EXPS}INIT
 done
 fi
 
done

echo " ...done!"
echo
