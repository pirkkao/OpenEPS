#!/bin/bash

# Madeleine Ekblom, 15.6.2017

#####################
##### COMMENTS ######

# True data: time: 0 0.4 0.8 ... (see truth/l95truetime.dat)
# Model data: runs from t0=0.4 (day1 start time), ... to t1=1.6 (day1 end time), ... (day2: t0=0.8 to t1=2.0)
# Scores are calculated at each end time by calculating rmse btw true data and model data at that time

### MODEL SPECIFIC STUFF IN ALGORITHM ###
# s0file.dat (input in l95)
# l95out.dat (output from l95)
# scores function (and its inputs)

### POSSIBLE IMPROVEMENTS 
# generate .nml instead of using pre-genereated files
# generation of true data --> beforehand or in script (before entering algorithm part)

### Run EPPES with Lorenz95 --> Save all possible outputs in dirs ###
###################
# Before running code, update:
# RUNDIR, EXPDIR, EPPES_EXE, L95_EXE, DAYS, ENS (possibly eppesconf-files if no. of ens changes)


### DEFINE VARIABLES ###
######################
# set directory where test is run:
RUNDIR=testrun # directory where all output is stored
EXPDIR=$HOME/Desktop/eppes_l95 # folder where this file is
INITVAL_DIR=${EXPDIR}/eppes_init # contains initial files for eppes + conf files for l95 and eppes (lorenz95.nml eppesconf_run.nml, eppesconf_init.nml)

# EPPES: executable and namelists
EPPES_EXE=$HOME/Desktop/eppes/eppes_routine
EPPES_INIT=${INITVAL_DIR}/eppesconf_init.nml # here: sampleonly=1
EPPES_RUN=${INITVAL_DIR}/eppesconf_run.nml # here: sampleonly=0

# LORENZ95: executable, namelist, true data, and true time
L95_EXE=$HOME/Documents/lorenz95f90/lorenz95run # l95 executable 
L95_NML=${INITVAL_DIR}/lorenz95.nml # l95 conffile
L95_DATA=${EXPDIR}/truth/l95truth40.dat # l95 true data, generated beforehand
L95_TIME=${EXPDIR}/truth/l95truetime.dat # l95 true time vector, generated beforehand

# Functions needed for EPPES algorithm
PAR_FUN=${EXPDIR}/pars_file.py # splits sampleout.dat into separate parameter files
SCORES_FUN=${EXPDIR}/scores.py # calculates scores for each pert.
SET_INIT_VAL=${EXPDIR}/set_init_values.py # reads true data and adds analysis error (sigma_a=0.05, defined in script)
SET_INIT_PERT=${EXPDIR}/set_pert_values.py # reads ctrl data and adds pert. noise (S0SIGMA), note that s0sigma in lorenz95.nml is set to 0 when pert initial values are generated beforehand

S0_SIGMA=0.1 # PERTURBATION standard deviation (from control)
AN_SIGMA=0.05 # CTRL standard deviation (from true data)

# set number of days to run algorithm
DAYS=3 # 0 days = only initialization of algorithm
# set number of ensembles here:
ENS=50 # number of ensemble members (apart from ctrl), nsample in eppesconf= ENS

# these are used when calculating scores 
T_DAY=160 # time corresponding to day at which forecasts ends, first round = t1 in lorenz95.nml, bash does not like float numbers --> T_DAY=T_DAY*100, FCLEN, starts from 0.4->first output at t=1.6
T_OUT=40 # time between ensembles, dout in lorenz95.nml --> T_OUT=T_OUT*100, DSTEP

### CREATE WORK STRUCTURE ###
#############################

echo "Create work structure"

# create run directory and init (store here all initial values)
mkdir -p ${RUNDIR}/init

cd ${RUNDIR}/init

# copy initial values and namelists to RUNDIR/init
for file in ${INITVAL_DIR}/* ; do
    cp $file .
done
cd ..

# DAY 0 contains only eppes initalization
mkdir -p day0/eppes

# LOOP OVER DAYS
for j in $(seq 1 $DAYS) ; do
    #create directory for eppes data for each day
    mkdir -p day${j}/eppes
    # create directory for control data for each day
    mkdir -p day${j}/ctrl
    # LOOP OVER PERT.
    for i in $(seq 1 $ENS) ; do
       	# create directories for each perturbation:
	mkdir -p day${j}/pert${i}
    done
 done 

# set PREV_DIR to be directory where EPPES init files are stored
PREV_DAY=${RUNDIR}/day0/eppes

### ALGORITHM ###
########################

echo "Algorithm"

# INITIALIZE ALGORITHM
echo "Day 0 - initalizing algorithm"
cd day0/eppes
# copy all files from init values
for file in ${EXPDIR}/${RUNDIR}/init/* ; do
    cp $file .
done

# run eppes with eppesconf_init
${EPPES_EXE} ${EPPES_INIT}
cp sampleout.dat oldsample.dat
cd ../..

echo "Algorithm - loop"
#LOOP OVER DAYS, j = day number when ensemble initialized (starts from day1)
for j in $(seq 1 $DAYS) ; do
    echo "Day" ${j}
    cd day${j}/ctrl
    # read in initial values from true data (jth index) and add noise, see python script from details
    python ${SET_INIT_VAL} ${L95_DATA} ${j} ${AN_SIGMA}
    # set s0file.dat to input file
    L95_INIT=${EXPDIR}/${RUNDIR}/day${j}/ctrl/s0file.dat
    cd ../..
    # LOOP OVER PERT. (run ensemble and calculate scores)
    for i in $(seq 1 $ENS) ; do
	cd day${j}/pert${i}
        # split sampleout to gupars.dat (ith row <-> ith pert)
	python ${PAR_FUN} ${EXPDIR}/${PREV_DAY}/sampleout.dat ${i}
	# generate initial value for pert. from ctrl data by adding random noise: N(0, S0_SIGMA^2), see python script for details
	python ${SET_INIT_PERT} ${L95_INIT} ${S0_SIGMA}
        # run lorenz95 with namelist
        ${L95_EXE} ${L95_NML}
        # calculate scores: RMSE from true data and model data, see python script for details
        python ${SCORES_FUN} ${L95_DATA} l95out.dat ${L95_TIME} ${T_DAY}
        # put scores_pert into common scores file
        cat scores_pert.dat >> ../ctrl/scores.dat
	cd ../..
    done
    # copy scores to eppes dir
    cp day${j}/ctrl/scores.dat day${j}/eppes/scores.dat
    # run eppes 
    cd day${j}/eppes
    # copy all .dat files from PREV_DAY to day{j}/eppes
    for file in ${EXPDIR}/${PREV_DAY}/*.dat ; do
	cp $file .
    done
    # run eppes_routine with namelist file (run-version)
    ${EPPES_EXE} ${EPPES_RUN}
    # copy sampleout to oldsample
    cp sampleout.dat oldsample.dat
    cd ../..
    # set PREV_DAY to be current day's eppes folder (used when running eppes routine for day j+1)
    PREV_DAY=${RUNDIR}/day${j}/eppes
    # set T_DAY so that it corresponds to the time of the following day, used when calculating scores 
    T_DAY=$((${T_DAY}+${T_OUT})) # increases with T_OUT (i.e. time btw "days", remember that this value is multiplied by 100 to work w/ l95
    # echo ${T_DAY}
done

echo "End of algorithm"

# END OF FILE
