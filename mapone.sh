#!/bin/sh

# --------------------------------------------------------------
# Script: mapone.sh
# Purpose: This script performs a series of NGS data processing tasks for a single sample.
# --------------------------------------------------------------

# Move to the working directory
cd $cwd

# Display basic information about the working environment
echo "##### INFORMATION #####"
echo -n "Working Directory : "
pwd
echo "Sample ID : "$id
echo "Output Directory : "$OUTDIR
echo "Sample Folder Name : "$SampleFolderName
echo "Bowtie2 Genome Index : "$INDEX
echo "##### INFORMATION #####"

# Activate the Conda environment
eval "$(~/miniconda3/bin/conda shell.bash hook)"
conda activate cfmedip
echo "conda activate cfmedip ... done"

# Run FastQC for initial quality check
echo "##### FastQC version check #####"
fastqc --version
echo "##### FastQC version check #####"

# If the FastQC output doesn't exist, perform FastQC
if [ ! -s $OUTDIR/fastqc/$SampleFolderName/$id\_R1_001_fastqc.html ]; then
  fastqc -o $OUTDIR/fastqc/$SampleFolderName $id\_R1_001.fastq.gz
fi

if [ ! -s $OUTDIR/fastqc/$SampleFolderName/$id\_R2_001_fastqc.html ]; then
  fastqc -o $OUTDIR/fastqc/$SampleFolderName $id\_R2_001.fastq.gz
fi

# Run Trim Galore for read trimming
echo "##### Trim Galore! version check #####"
trim_galore --version
echo "##### Trim Galore! version check #####"

# If the trimmed files don't exist, perform read trimming
if [ ! -s $OUTDIR/trimgalore/$SampleFolderName/$id\_R2_001_val_2.fq.gz ]; then
  trim_galore --fastqc --fastqc_args "-o $OUTDIR/fastqc/$SampleFolderName" \
      -o $OUTDIR/trimgalore/$SampleFolderName \
      --paired $id\_R1_001.fastq.gz $id\_R2_001.fastq.gz
fi

# Run Bowtie2 for read mapping
echo "##### Bowtie2-build version check #####"
bowtie2-build --version
echo "##### Bowtie2-build version check #####"

echo "##### Bowtie2 version check #####"
bowtie2 --version
echo "##### Bowtie2 version check #####"

echo "##### SAMtools version check #####"
samtools --version
echo "##### SAMtools version check #####"

# If the mapping output doesn't exist, perform read mapping
if [ ! -s $OUTDIR/bowtie2/$SampleFolderName/$id.bam ]; then
  bowtie2 -x $INDEX -p 2 -S $OUTDIR/bowtie2/$SampleFolderName/$id.sam \
    -1 $OUTDIR/trimgalore/$SampleFolderName/$id\_R1_001_val_1.fq.gz \
    -2 $OUTDIR/trimgalore/$SampleFolderName/$id\_R2_001_val_2.fq.gz
  # Remove reads with low mapping quality
  samtools view -bSq 20 $OUTDIR/bowtie2/$SampleFolderName/$id.sam > \
    $OUTDIR/bowtie2/$SampleFolderName/$id.bam
  rm $OUTDIR/bowtie2/$SampleFolderName/$id.sam
fi

# Cleanup: Remove the SAM file if the BAM file exists
if [ -s $OUTDIR/bowtie2/$SampleFolderName/$id.bam ]; then
  if [ -s $OUTDIR/bowtie2/$SampleFolderName/$id.sam ]; then
    rm $OUTDIR/bowtie2/$SampleFolderName/$id.sam
  fi
fi

###############################
# Convert SAM to BAM, sort, and index
###############################

# If the sorted BAM file doesn't exist or is incomplete, create it
if [ ! -s $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam ] || \
   [ -f  $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam.tmp.0000.bam ]; then
  rm -f $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam.*
  samtools sort $OUTDIR/bowtie2/$SampleFolderName/$id.bam \
    -o $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam
fi

# Create index for the sorted BAM file if it doesn't exist
if [ ! -s $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam.bai ]; then
  samtools index $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam
fi

# Remove PCR duplicates
# Reference: https://heavywatal.github.io/bio/samtools.html

# If the duplicate-removed BAM file doesn't exist, create it
if [ ! -s $OUTDIR/sortedbam_dup/$SampleFolderName/$id.sorted.bam ]; then
  # Cleanup: remove extraneous files from previous runs
  rm -f $OUTDIR/sortedbam_dup/$SampleFolderName/$id.positionsort.bam.*
  rm -f $OUTDIR/sortedbam_dup/$SampleFolderName/$id.namesort.bam.*
  
  # Sort by name (can be skipped if already sorted)
  samtools sort -n -o $OUTDIR/sortedbam_dup/$SampleFolderName/$id.namesort.bam $OUTDIR/sortedbam/$SampleFolderName/$id.sorted.bam

  # Add ms and MC tags for markdup to use later
  samtools fixmate -m $OUTDIR/sortedbam_dup/$SampleFolderName/$id.namesort.bam $OUTDIR/sortedbam_dup/$SampleFolderName/$id.fixmate.bam
  rm $OUTDIR/sortedbam_dup/$SampleFolderName/$id.namesort.bam

  # Sort by position for markdup
  samtools sort -o $OUTDIR/sortedbam_dup/$SampleFolderName/$id.positionsort.bam $OUTDIR/sortedbam_dup/$SampleFolderName/$id.fixmate.bam
  rm $OUTDIR/sortedbam_dup/$SampleFolderName/$id.fixmate.bam

  # Mark and remove duplicates
  samtools markdup -r -s $OUTDIR/sortedbam_dup/$SampleFolderName/$id.positionsort.bam $OUTDIR/sortedbam_dup/$SampleFolderName/$id.sorted.bam
  rm $OUTDIR/sortedbam_dup/$SampleFolderName/$id.positionsort.bam

  # Create index for the duplicate-removed BAM file
  samtools index $OUTDIR/sortedbam_dup/$SampleFolderName/$id.sorted.bam
fi

# Deactivate the Conda environment after the work is done
conda deactivate
echo "conda deactivate ... done"
