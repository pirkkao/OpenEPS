#!/bin/bash

# 16.6.2017
#
# This script needs improvements before it can be used, e.g.:
# 
# - conffiles could be generated instead of using pre-generated files
# - makefile functions put in separate scripts
# - check that the workflow is correct (e.g. all dependencies and rules)
# - at the moment, no errors when running this script nor when running the makefile. However, the workflow may not be completely correct 

# The three root directories

EPSDIR=
DEFDIR=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
RUNDIR=$(readlink -f run-eppes-l95)


# EPPES "executables"

EPPES_EXE=$HOME/Desktop/eppes/eppes_routine
SCORES_FUN=${DEFDIR}/scores.py # calculates scores for each ensemble member
OBS_ERROR=${DEFDIR}/set_init_values.py # reads true data and adds analysis error (an_sigma)
SET_PERT_VAL=${DEFDIR}/set_pert_values.py # reads ctrl data and adds perturbation (s0_sigma)

# Lorenz 95 exe and true data

L95_EXE=$HOME/Documents/lorenz95f90/lorenz95run
L95_DATA=${DEFDIR}/truth/l95truth40.dat # l95 true data, generated before-hand
L95_TIME=${DEFDIR}/truth/l95truetime.dat # l95 time vector corr. to true data

# namelists for eppes and lorenz 95

EPPES_INIT=${DEFDIR}/eppesconf_init.nml # here: sampleonly=1
EPPES_RUN=${DEFDIR}/eppesconf_run.nml # here: sampleonly=0
L95_NML=${DEFDIR}/lorenz95.nml # l95 conffile


# The number of the experiment days and the number of the ensemble members

DAY=1
ENS=5

# Standard deviation for input files

S0_SIGMA=0.1 # standard deviation of perturbation noise 
AN_SIGMA=0.05 # standard deviation of analysis noise

# These two values are needed for scores calculation (not the most beautiful..)

T_DAY=160 # end time*100 for day1 of first ensemble 
T_OUT=40 # time*100 between ensemble launches

####### FUNCTIONS FOR GENERATING CONFFILES #######

####### PLOTTING FUNCTION #######

######## PUT IN SEPARATE FILES: emember_makefile, eppes_makefile, eppes_init_makefile ########

# emember_makefile writes the Makefile corresponding to a single eppes run
#
# NOTE: This sub-makefile becomes part of the main Makefile at the RUNDIR root.
#       The current directory context 'CURDIR', in which Make interprets this
#       sub-makefile is 'RUNDIR', not the sub-directory in which this
#       sub-makefile is, 'RUNDIR/*'.

emember_makefile () {
    local currdir="day${1}/emember${2}"
    local prevdir="day$(( $1 - 1 ))/eppes"
    local ctrldir="day${1}/ctrl"
    cat > "${currdir}/Makefile" <<EOF

${currdir}/scores_pert.dat : ${SCORES_FUN} ${L95_DATA} ${currdir}/l95out.dat ${L95_TIME} 
	cd ${currdir}; python ${SCORES_FUN} ${L95_DATA} ${RUNDIR}/${currdir}/l95out.dat ${L95_TIME} $((${T_DAY}+${T_OUT}*(${1}-1) ))

${currdir}/l95out.dat : ${L95_NML} ${currdir}/gupars.dat ${currdir}/s0file.dat ${L95_EXE}
	cd ${currdir}; ${L95_EXE} ${L95_NML}

${currdir}/gupars.dat : ${prevdir}/sampleout.dat
	sed -n '${2}p' \$< > \$@

${currdir}/s0file.dat : ${ctrldir}/s0file.dat ${SET_PERT_VAL}
	cd ${currdir} ; python ${SET_PERT_VAL} ${RUNDIR}/${ctrldir}/s0file.dat ${S0_SIGMA}

EOF

}


# eppes_makefile
#
# NOTE: The same as previous...

eppes_makefile () {
    local currdir="day${1}/eppes"
    local prevdir="day$(( $1 - 1 ))/eppes"
    local ctrldir="day${1}/ctrl"
    local from_prev_day=(
        bounds.dat mufile.dat nfile.dat sigfile.dat wfile.dat)
    local cdirs=($(ls -w 0 -vd day${1}/emember*))
    cat > "${currdir}/Makefile" <<EOF

${currdir}/oldsample.dat : ${currdir}/sampleout.dat
	cp ${currdir}/sampleout.dat ${currdir}/oldsample.dat

${currdir}/sampleout.dat : ${EPPES_RUN} ${from_prev_day[@]/#/${currdir}/} ${currdir}/scores.dat ${prevdir}/oldsample.dat ${EPPES_EXE}
	cp ${prevdir}/oldsample.dat ${currdir}
	cd ${currdir}; ${EPPES_EXE} ${EPPES_RUN}

${from_prev_day[@]/#/${currdir}/} : ${from_prev_day[@]/#/${prevdir}/} ${prevdir}/oldsample.dat
	cp ${from_prev_day[@]/#/${prevdir}/} ${currdir}/

${currdir}/scores.dat : ${cdirs[@]/%//scores_pert.dat}
	cat ${cdirs[@]/%//scores_pert.dat} > \$@

${ctrldir}/s0file.dat : ${L95_DATA} ${OBS_ERROR}
	cd ${ctrldir} ; python ${OBS_ERROR} \$< ${1} ${AN_SIGMA}

EOF
}

eppes_init_makefile () {

cat > "day0/eppes/Makefile" <<EOF

day0/eppes/oldsample.dat : day0/eppes/sampleout.dat
	cp day0/eppes/sampleout.dat day0/eppes/oldsample.dat

day0/eppes/sampleout.dat : \$(addprefix day0/eppes/,bounds.dat mufile.dat nfile.dat sigfile.dat wfile.dat) ${EPPES_INIT} ${EPPES_EXE}
	cd day0/eppes; ${EPPES_EXE} ${EPPES_INIT}

EOF
}


#########
# CREATES WORK STRUCTURE 

mkdir -p ${RUNDIR}
pushd $_ > /dev/null

cp ${L95_NML} ${RUNDIR}/lorenz95.nml
cp ${EPPES_RUN} ${RUNDIR}/eppesconf_run.nml
cp ${EPPES_INIT} ${RUNDIR}/eppesconf_init.nml


# Day0 -- Run Eppes initialization, only

mkdir -p day0/eppes
cp ${DEFDIR}/eppes_init/*.dat day0/eppes
eppes_init_makefile 


# Each Day > 0: Run ensemble members, calculate scores, run Eppes

for j in $(seq 1 $DAY) ; do
    for i in $(seq 1 $ENS) ; do
	mkdir -p day${j}/emember${i}
        emember_makefile $j $i
    done
    mkdir -p day${j}/{eppes,ctrl}
    eppes_makefile $j
done

submakefiles=$(find day* -name Makefile -printf ' \\\n  %p')

cat > Makefile <<EOF
.PHONY: all
all: day${DAY}/eppes/oldsample.dat
include ${submakefiles}
EOF

popd > /dev/null
