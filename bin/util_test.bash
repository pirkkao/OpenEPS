#!/bin/bash
#
# Test that all vital paths/executables exist before
# entering job execution.
#

echo
echo "1) Testing for vital paths/executables..."

# Check that all vital paths exist
for target in $REQUIRE_PATHS; do
    # Accept other parallel task executions than mpirun
    if [ $target == "mpirun" ]; then
	target=$(basename $(which aprun 2> /dev/null || which srun 2> /dev/null || which mpirun 2> /dev/null ))
    fi
    
    if test -z ${!target}; then
	test -e ${target} || test ! -z $(which ${target}) || { echo "Non-existing path $target=${!target}"; exit 1; }
    else
	test -e ${!target} || test ! -z $(which ${!target}) || { echo "Non-existing path $target=${!target}"; exit 1; }
    fi
done

# Check that all vital executables exist
# (the list can consist of both absolute paths ${target} or variables ${!target})
for target in $REQUIRE_VARS; do
    if test -z ${!target} ; then
	echo "Non-existing variable $target"; exit 1
    elif test -z ${target}; then
	echo "Non-existing variable $target=${!target}"; exit 1
    fi
done


#echo ${!L*}

echo " ...tests passed!"
echo
