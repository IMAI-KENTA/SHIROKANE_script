#!/bin/sh

# --------------------------------------------------------------
# Script: multiqc.sh
# Purpose: This script runs MultiQC to aggregate quality control reports for each sample group.
# --------------------------------------------------------------

# Display basic information about the working environment
echo "##### INFORMATION #####"
echo -n "Working Directory : "
pwd
echo "Output Directory : "$OUTDIR
echo "Mapping Log : $LOG"
echo "Sample Folders : $SampleFolderNamesList"
echo "##### INFORMATION #####"

# Activate the Conda environment
eval "$(~/miniconda3/bin/conda shell.bash hook)"
conda activate cfmedip
echo "conda activate cfmedip ... done"

# Create the MultiQC output directory
mkdir -p $OUTDIR/multiqc

# Check MultiQC version
echo "##### MultiQC version check #####"
multiqc --version
echo "##### MultiQC version check #####"

# Loop through each sample group
for SampleFolderName in $SampleFolderNamesList; 
do 
    # Generate MultiQC report for FastQC results
    multiqc $OUTDIR/fastqc/$SampleFolderName/ --ignore *val* -f -o $OUTDIR/multiqc \
        -n $SampleFolderName\_fastqc_multiqc.html
        
    # Generate MultiQC report for FastQC results on trimmed reads
    multiqc $OUTDIR/fastqc/$SampleFolderName/*val* -f -o $OUTDIR/multiqc \
        -n $SampleFolderName\_fastqc_trimmed_multiqc.html
        
    # Generate MultiQC report for Trim Galore results
    multiqc $OUTDIR/trimgalore/$SampleFolderName -f -o $OUTDIR/multiqc \
        -n $SampleFolderName\_trimgalore_multiqc.html
    
    # Generate MultiQC report for Bowtie2 mapping results (uncomment if needed)
    # if [ $SampleFolderName = "PDAC" ]; then
    #    multiqc $LOG/*PDAC* -m bowtie2 -f -o $OUTDIR/multiqc \
    #        -n $SampleFolderName\_bowtie2_multiqc.html
    # elif [ $SampleFolderName = "NORMAL" ]; then
    #    multiqc $LOG/*NORMAL* -m bowtie2 -f -o $OUTDIR/multiqc \
    #        -n $SampleFolderName\_bowtie2_multiqc.html
    # fi
    
    # Generate MultiQC report for all Bowtie2 mapping results
    multiqc $LOG/ -m bowtie2 -f -o $OUTDIR/multiqc \
        -n all_bowtie2_multiqc.html
done

# Deactivate the Conda environment after the work is done
conda deactivate
echo "conda deactivate ... done"
