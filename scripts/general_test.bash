#!/bin/bash
#
# Test that all vital paths/executables exist before
# entering job execution.
#

echo
echo "1) Testing for vital paths/executables..."

# Check that all vital paths exist
for target in $VITAL_PATHS; do
    test -d ${!target} || { echo "Non-existing path $target=${!target}"; exit 1; }
done

# Check that all vital executables exist
# (the list can consist of both absolute paths ${target} or variables ${!target})
for target in $VITAL_EXECS; do
    if test -z ${!target} ; then
	test -f ${target} || { echo "Non-existing exec $target"; exit 1; }
    else
	test -f ${!target} || { echo "Non-existing exec $target=${!target}"; exit 1; }
    fi
done

# Check that all vital variables are defined
for target in $VITAL_VARS; do
    test ! -z ${!target} || { echo "Non-existing var $target=${!target}"; exit 1; }
done

echo ${!L*}

echo " ...tests passed!"
echo
