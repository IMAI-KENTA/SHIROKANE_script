#!/bin/sh

# --------------------------------------------------------------
# Script: merge.sh
# Purpose: This script merges lane-specific BAM files into a single BAM file for each sample.
# --------------------------------------------------------------

# Display basic information about the working environment
echo "##### INFORMATION #####"
echo -n "Working Directory : "
pwd
echo "Output Directory : "$OUTDIR
echo "Sample Folder Names : "$SampleFolderNamesList
echo "##### INFORMATION #####"

# Activate the Conda environment
eval "$(~/miniconda3/bin/conda shell.bash hook)"
conda activate cfmedip
echo "conda activate cfmedip ... done"

# Check SAMtools version
echo "##### SAMtools version check #####"
samtools --version
echo "##### SAMtools version check #####"

# Loop through each sample group
for SampleFolderName in $SampleFolderNamesList; 
do
    # Change directory to the group-specific folder containing duplicate-removed BAM files
    cd $OUTDIR/sortedbam_dup/$SampleFolderName
    
    # Loop through each lane-specific BAM file
    for firstlane in $( find . -type f -name "*_L001.sorted.bam" );
    do
        # Extract sample name from the first lane file
        sample=$(sed 's/_L001.sorted.bam//g' <<< $firstlane)
        
        # Merge all lane-specific BAM files for the sample
        samtools merge $sample.sorted.bam $sample\_L001.sorted.bam $sample\_L002.sorted.bam $sample\_L003.sorted.bam $sample\_L004.sorted.bam
        echo merging $SampleFolderName sample $sample
    done
done

# Deactivate the Conda environment after the work is done
conda deactivate
echo "conda deactivate ... done"
