#!/bin/bash
#
# Initialize paths etc.
#
#
echo
echo "Initializing experiment $EXP..."

# Make dirs
#
test -d $WORK | mkdir -p $WORK
test -d $SCRI | mkdir -p $SCRI
test -d $DATA | mkdir -p $DATA

# Paths for initial state generation
#
inibasedir=/wrk/ollinaho/data/init

# Paths for model
#
model=/homeappl/home/ollinaho/appl_sisu/oifs/intel/bin/master.exe
ifsdata=/appl/climate/ifsdata
ifsdata2=$WRKDIR/climate
grib_samples=/appl/climate/gcc491/share/grib_api/ifs_samples/grib1_mlgrib2
exp_data=$DATA/\$cdate/inistates

# Copy run scripts
#
for item in job.bash makefile pargen runmodel funceval mandtg; do
 cp -f scripts/$item $SCRI/.
done
cp -f scripts/postpro/calculate_cost_function_template_en.f90 $SCRI/calc_cost_en.f90

# Calculate cpu reservation
#
cpuspernode=16  # cpus per node 
timeformodel=10  # model run time in mins
# add routine for calculating number of dates
dates=2
# define parallelism
nodespermodel=2
ncpus=$(echo "$nodespermodel * $cpuspernode" | bc)
totaltime=$(echo "$timeformodel * $ENS * $dates" | bc)
parallels=$(echo "$NNODES / $nodespermodel" | bc)
reservation=$(echo "$totaltime / $parallels" | bc)

echo "The batch job will reserve $NNODES nodes for $reservation minutes!"
MODE=test # queue

# Modify genpar
#
sed -i -e "s/inibasedir=/inibasedir=${inibasedir//\//\/}/g" $SCRI/pargen
sed -i -e "s/exp_name=/exp_name=$EXPS/g"                    $SCRI/pargen

# Modify job.bash
#
sed -i -e "s/.*SBATCH -p test.*/#SBATCH -p $MODE/g"     $SCRI/job.bash
sed -i -e "s/.*SBATCH -J test.*/#SBATCH -J $EXPS/g"     $SCRI/job.bash
sed -i -e "s/.*SBATCH -t 5.*/#SBATCH -t $reservation/g" $SCRI/job.bash
sed -i -e "s/.*SBATCH -N 2.*/#SBATCH -N $NNODES/g"      $SCRI/job.bash
sed -i -e "s/per-node=16/per-node=$cpuspernode/g"       $SCRI/job.bash

# Modify runmodel
#
sed -i -e "s/oifs_exe=/oifs_exe=${model//\//\/}/g"                $SCRI/runmodel
sed -i -e "s/ifsdata=/ifsdata=${ifsdata//\//\/}/g"                $SCRI/runmodel
sed -i -e "s/ifsdata2=/ifsdata2=${ifsdata2//\//\/}/g"             $SCRI/runmodel
sed -i -e "s/grib_samples=/grib_samples=${grib_samples//\//\/}/g" $SCRI/runmodel
sed -i -e "s/exp_data=/exp_data=${exp_data//\//\/}/g"             $SCRI/runmodel
sed -i -e "s/oifs_res=/oifs_res=$RES/g"                           $SCRI/runmodel
sed -i -e "s/exp_name=/exp_name=$EXPS/g"                          $SCRI/runmodel

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
cp -f scripts/postpro/testi.f90          $SCRI/.

sed -i -e "s/lon=768/lon=$lon/g" $SCRI/testi.f90
sed -i -e "s/lat=384/lat=$lat/g" $SCRI/testi.f90
sed -i -e "s/lev=21/lev=$LEV/g"  $SCRI/testi.f90


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

for i in $(seq 1 $ENSN); do
 mkdir -p $SCRI/$SDATE/job$i
 echo >   $SCRI/$SDATE/job$i/input
 sed -n ${i}p params > job${i}/para

 # Initial states
 #
 i=$(echo "$i - 1" | bc)
 if [ $i -eq 0 ]; then
  name=ctrl
 elif [ $i -lt 10 ]; then
  name=pert00$name
 fi
 for item in CL GG SH; do
  if [ $item == GG ]; then
   cp -f ${inibasedir}/$SDATE/${name}_ICM${item}_INIUA $SCRI/$SDATE/inistates/${name}_ICM$item${EXPS}INIUA
  fi
  cp -f  ${inibasedir}/$SDATE/${name}_ICM${item}_INIT $SCRI/$SDATE/inistates/${name}_ICM$item${EXPS}INIT
 done

done

echo "...done!"
exit
