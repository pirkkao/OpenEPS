#!/bin/bash
#
# Initialize EPPES routine
#

# link eppes
ln -sf $EPPES_EXE $DATA/eppes/eppes_routine

#mufile
printf "%s\n" "2.0" > $DATA/eppes/mufile.dat
#printf "%s\n" "2.0" >> $DATA/eppes/mufile.dat

#sigfile
printf "%s\n" "0.4" > $DATA/eppes/sigfile.dat
#printf "%s\n" "0 2.0" >> $DATA/eppes/sigfile.dat

#bounds
printf "%s\n" "0.5 4.0" > $DATA/eppes/bounds.dat
#printf "%s\n" "1.0 4.0" >> $DATA/eppes/bounds.dat

#nfile
printf "%s\n" "10" > $DATA/eppes/nfile.dat
#printf "%s\n" "2.0" >> $DATA/eppes/nfile.dat

#wfile
printf "%s\n" "1" > $DATA/eppes/wfile.dat
#printf "%s\n" "0 2" >> $DATA/eppes/wfile.dat


# ! THIS IS A LOT SIMPLER TO JUST DO BY HAND,
# ! RETHINK IF THIS WOULD BE WORTH IT

if [ 1 -eq 0 ]; then
# Params (mu, sig, lower bound, upper bound)
# ENTSHALP
PAR1=(2.0 0.4 0.5 4.0)
PAR2=(1.0 0.2 0.1 2.0)

ipar=1
mu=()
sig=()
bnd=()
n=()
w=()

while [ 1 ]; do
    temp=PAR$ipar[@]
    tmp2=PAR$ipar[0]
    if [ ! -z ${!tmp2} ]; then	
	# Un- and reroll array
	par=()
	for iatt in ${!temp}; do
	    par+=($iatt)
	done

	# mufile
	mu+=(${par[0]})

	# sigfile
	sig+=(${par[1]})

	# bounds
	bnd+=("${par[2]} ${par[3]}")

	
	(( ipar += 1 ))
    else
	echo $ipar
	break
    fi
done

# Write out necessary files
#
rm -f $DATA/eppes/mufile.dat $DATA/eppes/bounds.dat $DATA/eppes/sigfile.dat

# loop over pars
lead=0
trail=$(( ${#mu[@]} - 1))
aa='"%s %s %s \n"'
for ipar in $(seq 0 $(( ${#mu[@]} - 1)) ); do
    printf "%s\n"    ${mu[$ipar]}  >> $DATA/eppes/mufile.dat
    printf "%s %s\n" ${bnd[$ipar]} >> $DATA/eppes/bounds.dat

    printf $aa $lead ${sig[$ipar]} $trail >> $DATA/eppes/sigfile.dat
    
    (( lead += 1 ))
    (( trail += 1 ))
done
fi

# eppes sampleonly namelist
cat > $DATA/eppes/eppesconf_init.nml <<EOF
&eppesconf
 sampleonly = 1
 nsample    = $ENS
 maxn0 = 10
 mufile    = 'mufile.dat'
 sigfile   = 'sigfile.dat'
 wfile     = 'wfile.dat'
 nfile     = 'nfile.dat'
 sampleout = 'sampleout.dat'
 boundsfile = 'bounds.dat'
/
EOF

# eppes update namelist
cat > $DATA/eppes/eppesconf_run.nml <<EOF
&eppesconf
 sampleonly = 0
 nsample    = $ENS
 maxn0 = 10
 mufile    = 'mufile.dat'
 sigfile   = 'sigfile.dat'
 wfile     = 'wfile.dat'
 nfile     = 'nfile.dat'
 samplein  = 'oldsample.dat'
 sampleout = 'sampleout.dat'
 scorefile = 'scores.dat'
 boundsfile = 'bounds.dat'
 winfofile = 'winfo.dat'
 combine_method = 'amean'
/
EOF


# run sampleonly
pushd $DATA/eppes > /dev/null
cp -f eppesconf_init.nml eppesconf.nml
./eppes_routine

# change nml to production
cp -f eppesconf_run.nml eppesconf.nml

# store init values
mkdir -p init
for item in mu sig n w; do
    cp ${item}file.dat init/.
done
cp sampleout.dat init/.

popd > /dev/null

