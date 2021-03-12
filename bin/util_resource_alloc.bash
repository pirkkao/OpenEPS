#!/bin/bash
#
# Resource calculations
#

# Dates
dates=1
date=$SDATE
while [ $date -lt $EDATE ]; do
    if [ -e $WORK/mandtg ]; then
	date=$(exec $WORK/mandtg $date + $DSTEP)
    else
	date=$(($date + $DSTEP))
    fi
    ((dates+=1))
done

# Define parallelism
#
totncpus=$CPUSTOT

# Check does a single model take more than one node
nodespermodel=1
cpus=$CPUSPERMODEL
while [ $cpus -gt $SYS_CPUSPERNODE ]; do
    cpus=$(echo "$cpus - $SYS_CPUSPERNODE" | bc)
    ((nodespermodel+=1))
done

if [ $cpus -gt $totncpus ]; then
    echo "ILLEGAL RESOURCE ALLOCATION!"
    exit
fi

# Note! In some systems parallels can run only in the same node and/or 
# in different nodes, need to check that no inter-node parallelism is 
# allocated. The following does not matter in the case of the latter.
#
# Disabled for now.
#
#parallels_in_node=$(echo $SYS_CPUSPERNODE / $CPUSPERMODEL | bc)

# Safety check if running on non-full nodes
#if [ $CPUSTOT -lt $SYS_CPUSPERNODE ]; then
#    parallels_in_node=$(echo $CPUSTOT / $CPUSPERMODEL | bc)
#fi

# Fix parallels to be at least 1
#if [ $parallels_in_node -eq 0 ]; then
#    parallels_in_node=1
#fi

parallels_in_node=1

parallel_nodes=$(echo "$totncpus / $cpus / $parallels_in_node" | bc)

#
# Define (MPI) launcher
# Skip if $launcher defined in env.*
#

if [ -n "$launcher" ]; then

  parallel=$launcher
  serial="bash"

else
  launcher=$(basename $(which aprun 2> /dev/null || which srun 2> /dev/null || which mpirun 2> /dev/null || which bash ))

  case "$launcher" in
    aprun|srun)
	parallel="$launcher -n $CPUSPERMODEL"
	serial="bash"
	    ;;
    mpirun)
	parallel="$launcher -np $CPUSPERMODEL"
	serial="bash"
	;;
    *)
	printf "%s" "PARALLEL JOB LAUNCHER $parallel NOT CODED IN, ADD IT TO util_resource_alloc"
	exit
	;;
  esac
fi


# Write a source file
cat <<EOF > $SRC/resources
#!/bin/bash
export PARALLELS_IN_NODE=$parallels_in_node
export PARALLEL_NODES=$parallel_nodes
export parallel="$parallel"
export serial="$serial"

export VERBOSE=$VERBOSE
export SUBDIR_NAME=$SUBDIR_NAME
EOF
