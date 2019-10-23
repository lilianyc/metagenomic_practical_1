#!/usr/bin/env bash

# The script assumes files are arranged according to the practical directory,
# and it is launched from the root of the repository.
# It takes 2 positional arguments: raw_reads_dir and output_dir.
# The directory shall not have "/" suffixed.


# Positional arguments
raw_reads_dir=$1
output_dir=$2

# Global variables.
software_dir=soft
db_dir=databases
DEBUG=1

echo "raw reads directory: $raw_reads_dir"
echo "output directory: $output_dir"

## Preprocessing of files and softwares.
# Creating the AlienTrimmer binary.
echo "Creating the AlienTrimmer binary ..."
cd $software_dir
./JarMaker.sh AlienTrimmer.java
cd -

# Unzip the gz files to get fastq files.
echo "Unzipping fastq.gz files ..."
gunzip $raw_reads_dir/*.fastq.gz


# Creating the output directory.
mkdir $output_dir

# Trimming with AlienTrimmer, assuming only fastq in the raw reads directory
# and merging with Vsearch.
for file in $(ls $raw_reads_dir/*_R1.fastq); do
    name_R1=$(echo $file|sed "s:$raw_reads_dir\/::g")
    name_R2=$(echo $file|sed "s:R1:R2:g"|sed "s:$raw_reads_dir\/::g")
    # Get the stem of the filename.
    sample_name=$(echo $name_R1|sed "s:_R.\.fastq$::g")

    # Trimming.
    java -jar $software_dir/AlienTrimmer.jar\
         -if $raw_reads_dir/$name_R1 -ir $raw_reads_dir/$name_R2 \
         -of $output_dir/$name_R1 -or $output_dir/$name_R2 \
         -os $output_dir/$sample_name.at.sgl.fq \
         -c $db_dir/contaminants.fasta -q 20

    # Merging.
    $software_dir/vsearch --fastq_mergepairs $output_dir/$name_R1 \
                 --reverse $output_dir/$name_R2 \
                 --fastaout $output_dir/$sample_name \
                 --label_suffix ";sample=$sample_name"

    # Remove spaces in resulting fasta and append to amplicon.fasta.  
    sed "s: ::g" $output_dir/$sample_name >> $output_dir/amplicon.fasta
    # Take only the first paired files for debugging.
    if [[ $DEBUG -ne 0 ]];then
        break
    fi
done


## Working on amplicon.fasta
# Dereplicating the sequences.
$software_dir/vsearch --derep_fulllength $output_dir/amplicon.fasta \
                      --output $output_dir/dereplicated.fasta \
                      --minuniquesize 10 --sizeout

# Take non chimeric sequences.
$software_dir/vsearch --uchime_denovo $output_dir/dereplicated.fasta \
                      --nonchimeras $output_dir/non_chimera.fasta

# Clustering with abundance.
$software_dir/vsearch --cluster_size $output_dir/non_chimera.fasta \
                      --centroids $output_dir/centroids.fasta \
                      --otutabout $output_dir/otu.tsv \
                      --relabel "OTU_" --id 0.97

# Get a count table.
$software_dir/vsearch --usearch_global $output_dir/amplicon.fasta \
                      --db $output_dir/centroids.fasta \
                      --otutabout $output_dir/count_table.tsv --id 0.97

# Annotate OTU.
$software_dir/vsearch --usearch_global $output_dir/centroids.fasta \
                      --db $db_dir/mock_16S_18S.fasta \
                      --userout $output_dir/annotated.tsv \
                      --id 0.97 --top_hits_only --userfields "query+target"

