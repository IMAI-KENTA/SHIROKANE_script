#!/bin/sh
#$ -cwd

# --------------------------------------------------------------
# Script: mapall.sh
# Purpose: This script iterates through project directories and triggers mapone.sh for each sample.
# --------------------------------------------------------------

# Display basic information about the working environment
echo "##### INFORMATION #####"
echo -n "Working Directory : "
pwd
echo "Script Directory : "$SCRIPTDIR
echo "Data Directory : "$DATDIR
echo "Output Directory : "$OUTDIR
echo "Mapping Log : $LOG"
echo "Sample Folder Names : $SampleFolderNamesList"
echo "##### INFORMATION #####"

# Loop through project directories
# Here, only one group S230527 is processed. Expand this for multiple groups.
for SampleFolderName in $SampleFolderNamesList; 
do
    # Create necessary directories for each group
    mkdir -p $OUTDIR/fastqc/$SampleFolderName
    mkdir -p $OUTDIR/trimgalore/$SampleFolderName
    mkdir -p $OUTDIR/bowtie2/$SampleFolderName
    mkdir -p $OUTDIR/sortedbam/$SampleFolderName
    mkdir -p $OUTDIR/sortedbam_dup/$SampleFolderName
    mkdir $DATDIR/$SampleFolderName
    export SampleFolderName

    # Change to the data directory for the group
    cd $DATDIR/$SampleFolderName

    # Loop through each fastq file and submit mapone.sh for processing
    for fq in $(find . -type f -name "*_R1_001.fastq.gz");
    do
        # Extract the sample ID from the fastq file name
        id=$(sed 's/\.\///g' <<< $(sed 's/_R1_001.fastq.gz//g' <<< $fq))
        echo processing $SampleFolderName sample $id
        RUN=TRUE

        # Check if the processed file already exists. If yes, skip processing.
        if [ -s $OUTDIR/sortedbam_dup/$SampleFolderName/$id.sorted.bam ]; then
          RUN=FALSE
        fi

        # If the processed file doesn't exist, submit mapone.sh for processing
        if [[ $RUN = TRUE ]]; then
           export id
           export cwd=$PWD
           qsub -N mapall_$id\_$SampleFolderName -l s_vmem=20G -o $LOG/Processing_$SampleFolderName\_$id.out -e $LOG/Processing_$SampleFolderName\_$id.err -V $SCRIPTDIR/mapone.sh
        fi    
    done  
done

