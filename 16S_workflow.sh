#!/usr/bin/env bash

# The script assumes files are arranged according to the practical directory.
# It takes 2 positional arguments.

# Positional arguments
raw_reads_dir=$1
output_dir=$2

# Global variables.


echo "raw reads directory: $raw_reads_dir"
echo "output directory: $output_dir"

# Creating the output directory.
mkdir $output_dir

# Creating the AlienTrimmer binary.
./soft/JarMaker.sh soft/AlienTrimmer.java

# Unzip the gz files to get fastq files.
echo "Unzipping fastq.gz files"
gunzip $raw_reads_dir/*.fastq.gz

# Here it supposes the dir name has no "/" appended.
for file in $raw_reads_dir/*.fastq; do
    #fastqc $file -o $output_dir
    java -jar soft/AlienTrimmer.jar -i $file -q 20 -c databases/contaminants.fasta
done

#for file in $(ls $raw_reads_dir); do
#    name_R1="$file"
#    name_R2= 'echo $file|sed "s:R1:R2:g"'
#    echo tes $name_R1 $name_R2
#done


