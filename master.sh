#!/bin/sh
#$ -cwd
#$ -o /dev/null
#$ -e /dev/null

# --------------------------------------------------------------
# Script: master.sh
# Purpose: This is the master script to control the entire NGS data processing pipeline.
# --------------------------------------------------------------

# Display basic information about the working environment
echo "##### INFORMATION #####"
echo -n "Working Directory : "
pwd
echo "##### INFORMATION #####"

# Setting Variables
# Define directories and index for data processing
OUTDIR=/home/username/NGS
LOG=/home/username/NGS/processing_log
SCRIPTDIR=/home/username/SHIROKANE_script
DATDIR=/home/username/rawdata
INDEX=/home/username/ReferenceGenomes/hg38
SampleFolderNamesList="S220312 S220406 S220927 S230210 S230419 S230825 S230829 S220329 S220621 S221021 S230221 S230527 S230826"

# Create the log directory if it doesn't exist
mkdir -p $LOG

# Export variables for use in child scripts
export OUTDIR
export LOG
export SCRIPTDIR
export DATDIR
export INDEX
export SampleFolderNamesList

# Change to the output directory
cd $OUTDIR

# First Stage (mapall.sh)
# Submit mapall.sh script to the job queue and wait for its completion
qsub -N mapall \
-o $OUTDIR/mapall.out \
-e $OUTDIR/mapall.err \
-V $SCRIPTDIR/mapall.sh

# Wait until the mapall job is finished
while [[ $(qstat -r | grep mapall | wc | awk '{print $1}') > 0 ]]
do
  sleep 10
done

# Second Stage (merge.sh)
# Similar to the first stage, but this time for merge.sh
qsub -N merge \
-o $OUTDIR/merge.out \
-e $OUTDIR/merge.err \
-V $SCRIPTDIR/merge.sh

# Wait until the merge job is finished
while [[ $(qstat -r | grep merge | wc | awk '{print $1}') > 0 ]]
do
  sleep 10
done

# Third Stage (multiqc.sh)
# Similar to the first and second stages, but this time for multiqc.sh
qsub -N multiqc \
-l s_vmem=100G \
-o $OUTDIR/multiqc.out \
-e $OUTDIR/multiqc.err \
-V $SCRIPTDIR/multiqc.sh
