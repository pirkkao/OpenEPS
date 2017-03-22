#!/bin/bash
#
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


# Write a source file
cat <<EOF > $SRC/resources
#!/bin/bash
export PARALLELS_IN_NODE=$parallels_in_node
export PARALLEL_NODES=$parallel_nodes

EOF