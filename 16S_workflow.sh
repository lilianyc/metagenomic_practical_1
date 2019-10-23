#!/usr/bin/env bash

# The script assumes files are arranged according to the practical directory.
# It takes 2 positional arguments.

# Positional arguments
raw_reads_dir=$1
output_dir=$2

# Global variables.


echo "raw reads directory: $raw_reads_dir"
echo "output directory: $output_dir"

## Preprocessing of files and softwares.
# Creating the AlienTrimmer binary.
echo "Creating the AlienTrimmer binary ..."
# Does not work
#pwd/soft/JarMaker.sh soft/AlienTrimmer.java

# Unzip the gz files to get fastq files.
echo "Unzipping fastq.gz files ..."
gunzip $raw_reads_dir/*.fastq.gz


# Creating the output directory.
mkdir $output_dir

# Trimming with AlienTrimmer, assuming only fastq in the raw reads directory
# and merging with Vsearch.
: '
for file in $(ls $raw_reads_dir/ *_R1.fastq); do
    name_R1="$file"
    name_R2=$(echo $file|sed "s:R1:R2:g")
    # Trimming.
    java -jar soft/AlienTrimmer.jar -if $raw_reads_dir/$name_R1 -ir $raw_reads_dir/$name_R2 -q 20 -c databases/contaminants.fasta -of $output_dir/$name_R1 -or $output_dir/$name_R2
    # Merging.
    sample_name=$(echo $file|sed "s:_R.\.fastq$::g")
    soft/vsearch --fastq_mergepairs $output_dir/$name_R1 --reverse $output_dir/$name_R2 --fastaout $output_dir/$sample_name --label_suffix ";sample=$sample_name"
    # Removing spaces.  
    sed "s: ::g" $output_dir/$sample_name >> $output_dir/amplicon.fasta
done
'

# Working on amplicon.fasta
soft/vsearch --derep_fulllength $output_dir/amplicon.fasta --sizeout --output tmp.fasta




