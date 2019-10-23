#!/usr/bin/env bash

# The script assumes files are arranged according to the practical directory.
# It takes 2 positional arguments.

raw_reads_dir=$1
output_dir=$2

echo "raw reads directory: $raw_reads_dir"
echo "output directory: $output_dir"

mkdir $output_dir


# Here it supposes the dir name has no "/" appended.
for file in $raw_reads_dir/*.fastq.gz; do
    fastqc $file -o $output_dir
done
