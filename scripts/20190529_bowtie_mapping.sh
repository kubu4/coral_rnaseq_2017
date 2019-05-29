#!/bin/bash

# Exit if command fails
set -e

threads=28

# Paths to programs
blast_dir="/gscratch/srlab/programs/ncbi-blast-2.8.1+/bin"
blastx="${blast_dir}/blastx"
seqtk="/gscratch/srlab/programs/seqtk-1.3/seqtk"

# Paths to blastdbs
blastdb_dir="/gscratch/srlab/blastdbs/ncbi-sp-v5"
blast_db="${blastdb_dir}/swissprot_v5"
samtools="/gscratch/srlab/programs/samtools-1.9/samtools"

# Input files
fastq_dir="/gscratch/srlab/sam/data/metagenomics/P_generosa/"


## Inititalize arrays
fastq_array_R1=()
fastq_array_R2=()
names_array=()

# Create array of fastq R1 files
for fastq in ${fastq_dir}/*R1*.gz
do
  fastq_array_R1+=(${fastq})
done

# Create array of fastq R2 files
for fastq in ${fastq_dir}/*R2*.gz
do
  fastq_array_R2+=(${fastq})
done

# Create array of sample names
## Uses parameter substitution to strip leading path from filename
## Uses awk to parse out sample name from filename
for R1_fastq in ${fastq_dir}/*R1*.gz
do
  names_array+=($(echo ${R1_fastq#${fastq_dir}} | awk -F"_" '{print $3 $4}'))
done

# Create list of fastq files used in analysis
## Uses parameter substitution to strip leading path from filename
for fastq in ${fastq_dir}*.gz
do
  echo "${fastq#${fastq_dir}}" >> fastq.list.txt
done

# Concatenate paired-end reads into singular FastA files for each sample.
# Uses seqtk to convert FastQ to FastA.
for index in "${!fastq_array_R1[@]}"
do
  sample_name=$(echo "${names_array[index]}")
  if [ "${sample_name}" == "MG1" ] \
  || [ "${sample_name}" == "MG2" ] \
  || [ "${sample_name}" == "MG5" ]
  then
    sample_name="${sample_name}"_pH82
  else
    sample_name="${sample_name}"_pH71
  fi
  "${seqtk}" seq -a "${fastq_array_R1[index]}" "${fastq_array_R2[index]}" >> "${sample_name}".fasta
done
