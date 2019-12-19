#!/bin/bash

# Get date
date=${1:-$cdate}

# Get process id
nid=$(pwd | grep -o -P "$SUBDIR_NAME.{0,5}" | sed -e "s/$SUBDIR_NAME//g")

# Log
echo `date +%H:%M:%S` link "   " $SUBDIR_NAME${nid} >> $WORK/master.log

# pert000 is ctrl
if [ $nid -eq 0 ]; then
    name=ctrl
else
    name=$SUBDIR_NAME$nid
fi

# Copy namelist
cp -f $SCRI/namelist.$name fort.4

# Under which alias the unperturbed ini is
ename=oifs

# Set initial perturbations off if INIPERT variable is not set
if [ -z $INIPERT ]; then
    INIPERT=0
fi

# Clean directory
rm -f ICM*+00*

# Link or create day specific fields
if [ $RES -ne 21 ]; then # T21 does not need the climate file
    ln -sf ${IFSDATA}/t${RES}/$date/ICMCL${ename}INIT.1  ICMCL${EXPS}INIT
fi

if [ $nid -eq 0 ] || [ $INIPERT -eq 0 ]; then
    ln -sf ${IFSDATA}/t${RES}/$date/ICMGG${ename}INIT  ICMGG${EXPS}INIT
    ln -sf ${IFSDATA}/t${RES}/$date/ggml$RES           ICMGG${EXPS}INIUA
    ln -sf ${IFSDATA}/t${RES}/$date/ICMSH${ename}INIT  ICMSH${EXPS}INIT

else
    # Pick odd initial state pertubations
    if [ ! -z $INIFAIR ] && [ $INIFAIR -eq 1 ]; then
	nid=$((10#$nid * 2 - 1)) # force into 10-base number with 10#
	nid=$(printf '%03d' $nid)
    fi

    # Change initial state perturbation amplitude if defined
    # SV
    if [ -z $INIPERT_AMPLITUDE_SV ] ; then
	swi_sv=false
    elif [ 1 -eq $(echo "$INIPERT_AMPLITUDE_SV == 1.0" | bc) ]; then
	swi_sv=false
    else
	amp_sv=$INIPERT_AMPLITUDE_SV
	swi_sv=true
    fi

    # EDA
    if [ -z $INIPERT_AMPLITUDE_EDA ] ; then
	swi_eda=false
    elif [ 1 -eq $(echo "$INIPERT_AMPLITUDE_EDA == 1.0" | bc) ]; then
	swi_eda=false
    else
	amp_eda=$INIPERT_AMPLITUDE_EDA
	swi_eda=true
    fi


    gginit=${IFSDATA}/t${RES}/$date/ICMGG${ename}INIT
    gginiua=${IFSDATA}/t${RES}/$date/ggml$RES
    shinit=${IFSDATA}/t${RES}/$date/ICMSH${ename}INIT

    gginit_pert=${IFSDATA}/t${RES}/$date/psu_$nid
    gginiua_pert=${IFSDATA}/t${RES}/$date/pan_$nid
    shinit_pert=${IFSDATA}/t${RES}/$date/pua_$nid
    
    sv_pert=${IFSDATA}/t${RES}/$date/pert_$nid

    # GGINIT
    if [ $INIPERT_TYPE == 'sv' ]; then
        # Grid space perturbations are only from EDA.
        # If only SVs requested use control fields instead.
	ln -sf $gginit ICMGG${EXPS}INIT
	
    elif $swi_eda ; then
       # get perturbations
	$GRIBTOOLS/grib_set -s edition=1 $gginit gginit
	$GRIBTOOLS/grib_set -s edition=1 $gginit_pert gginit_pert
	cdo -sub gginit_pert gginit pert

	# change perturbation magnitude
	cdo -mulc,$amp_eda pert pert_dot

	# add back to unperturbed fields
	cdo -add gginit pert_dot pert_fin
	$GRIBTOOLS/grib_set -s edition=2 -s gridType=reduced_gg pert_fin ICMGG${EXPS}INIT
	rm -f pert pert_dot gginit gginit_pert pert_fin

    else
	# Link original perturbation field
	ln -sf $gginit_pert ICMGG${EXPS}INIT
    fi

    # GGINIUA
    if [ $INIPERT_TYPE == 'sv' ]; then
        # Grid space perturbations are only from EDA.
        # If only SVs requested use control fields instead.
	ln -sf $gginiua ICMGG${EXPS}INIUA

    elif $swi_eda ; then
       # get perturbations
	$GRIBTOOLS/grib_set -s edition=1 $gginiua gginiua
	$GRIBTOOLS/grib_set -s edition=1 $gginiua_pert gginiua_pert
	cdo -sub gginiua_pert gginiua pert

        # change perturbation magnitude
	cdo -mulc,$amp_eda pert pert_dot

        # add back to unperturbed fields
	cdo -add gginiua pert_dot pert_fin
	$GRIBTOOLS/grib_set -s edition=2 -s gridType=reduced_gg pert_fin ICMGG${EXPS}INIUA
	rm -f pert pert_dot gginiua gginiua_pert pert_fin

    else
	# Link original perturbation field
	ln -sf $gginiua_pert ICMGG${EXPS}INIUA
    fi

    # SHINIT
    # Get SV structures if not requesting both perturbations
    if [ ! $INIPERT_TYPE == 'both' ] || $swi_eda || $swi_sv ; then

        # get perturbations
	cdo -sp2gpl $shinit tmp_init
	cdo -sp2gpl $shinit_pert tmp_pert
	cdo -sub tmp_pert tmp_init pert
	rm -f tmp_pert

        # extract SV structures
	cdo -sp2gp $sv_pert tmp_pert
        # need to separate the fields, CDO bugs out in multi-field substraction
	cdo -selvar,t    tmp_pert sv_t
	cdo -selvar,d    tmp_pert sv_d
	cdo -selvar,vo   tmp_pert sv_vo
	cdo -selvar,lnsp tmp_pert sv_lnsp
	rm -f tmp_pert

        # separate input fields to match those in SVs
	cdo -selvar,t    pert pert_t
	cdo -selvar,d    pert pert_d
	cdo -selvar,vo   pert pert_vo
	cdo -selvar,lnsp pert pert_lnsp
	cdo -selvar,z    pert pert_z

        # change resolution to match other fields
	cdo -genbil,pert_t sv_t grid
	cdo -remap,pert_t,grid sv_t    sv_t_hr
	cdo -remap,pert_t,grid sv_d    sv_d_hr
	cdo -remap,pert_t,grid sv_vo   sv_vo_hr
	cdo -remap,pert_t,grid sv_lnsp sv_lnsp_hr
	rm -f tmp grid sv_t sv_d sv_vo sv_lnsp

	if [ $INIPERT_TYPE != 'sv' ]; then
            # remove SVs from perts
	    cdo -sub pert_t    sv_t_hr    tmp_t
	    cdo -sub pert_d    sv_d_hr    tmp_d
	    cdo -sub pert_vo   sv_vo_hr   tmp_vo
	    cdo -sub pert_lnsp sv_lnsp_hr tmp_lnsp
	    cdo -merge tmp_t tmp_vo tmp_d tmp_lnsp pert_z pert_eda

            rm -f tmp_t tmp_d tmp_vo tmp_lnsp pert_z

	    # Increase amplitude if requested
	    if $swi_eda ; then
		cdo -mulc,$amp_eda pert_eda pert_eda_dot
		rm -f pert_eda
	    else
		mv pert_eda pert_eda_dot
	    fi

	    # Change name if not requesting both perturbation types
	    if [ $INIPERT_TYPE != 'both' ]; then
		mv pert_eda_dot pert_dot
		rm -f sv_*_hr
	    fi
	fi

	if [ $INIPERT_TYPE != 'eda' ]; then
	    # create a zero-field for z 
	    cdo -selvar,z tmp_init ini_z
	    cdo -sub ini_z ini_z zero_z
	    rm -f ini_z

	    # merge fields
	    cdo -merge sv_t_hr sv_vo_hr sv_d_hr sv_lnsp_hr zero_z pert_sv

	    rm -f sv_*_hr zero_z

	    # Increase amplitude if requested
	    if $swi_sv ; then
		cdo -mulc,$amp_sv pert_sv pert_sv_dot
		rm -f pert_sv
	    else
		mv pert_sv pert_sv_dot
	    fi

	    # Change name if not requesting both perturbation types
	    if [ $INIPERT_TYPE != 'both' ]; then
		mv pert_sv_dot pert_dot
	    fi
	fi
	rm -f pert_t pert_d pert_vo pert_lnsp pert_z

	# Add perturbations together
	if  [ $INIPERT_TYPE == 'both' ]; then
	    cdo -add pert_eda_dot pert_sv_dot pert_dot
	    rm -f pert_eda_dot pert_sv_dot
	fi

        # add back to unperturbed fields
	cdo -add tmp_init pert_dot pert_fin
	cdo -gp2spl pert_fin ICMSH${EXPS}INIT
	rm -f tmp_init pert pert_dot pert_fin

    else
	# Link original perturbation field
	ln -sf $shinit_pert ICMSH${EXPS}INIT
    fi
fi

# Link climatologies
ln -sf ${IFSDATA}/climatology/ifsdata .
ln -sf ${IFSDATA}/rtables
if [ $RES -eq 21 ]; then
    ln -sf ${IFSDATA}/38r1/climate/${RES}_full
else
    ln -sf ${IFSDATA}/38r1/climate/${RES}l_2
fi

