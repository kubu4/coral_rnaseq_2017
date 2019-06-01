#!/bin/env bash

# Exit if command fails
set -e

# Number of threads to use for programs
threads=23

# Paths to programs
bt2="/home/shared/bowtie2-2.3.4.1-linux-x86_64/bowtie2"
samtools="/home/shared/samtools-1.9/samtools"
picard="/home/shared/picard-2.20.2.jar"

# Input files
fastq_dir="/mnt/data/coral_RNAseq_2017/montipora/20180415_trimmed"
bt2_index_dir="/media/sam/4TB_toshiba/montipora/20180416_trinity/"
bt2_index_name="montipora_all"

## Inititalize arrays
fastq_array_R1=()
fastq_array_R2=()
names_array=()

# Copy bowtie2 index files
rsync -av "${bt2_index_dir}"*.bt2 .

# Create array of fastq R1 files
for fastq in ${fastq_dir}/*READ1*.gz
do
  fastq_array_R1+=(${fastq})
done

# Create array of fastq R2 files
for fastq in ${fastq_dir}/*READ2*.gz
do
  fastq_array_R2+=(${fastq})
done

# Create array of sample names
## Uses parameter substitution to strip leading path from filename
## Uses awk to parse out sample name from filename
for R1_fastq in ${fastq_dir}/*READ1*.gz
do
  names_array+=($(echo ${R1_fastq#${fastq_dir}} | awk -F'-' '{print $3}'))
done

# Create list of fastq files used in analysis
## Uses parameter substitution to strip leading path from filename
for fastq in ${fastq_dir}*READ*.gz
do
  echo "${fastq#${fastq_dir}}" >> fastq.list.txt
done


for index in "${!fastq_array_R1[@]}"
do
  sample_name=$(echo "${names_array[index]}")
  if [ "${sample_name}" == "P01" ]
  then
    sample_name="${sample_name}"-male_bleached_K5
  elif [ "${sample_name}" == "P02" ]
  then
    sample_name="${sample_name}"-female_nonbleached_K5
  elif [ "${sample_name}" == "P03" ]
  then
    sample_name="${sample_name}"-female_bleached_44
  elif [ "${sample_name}" == "P04" ]
  then
    sample_name="${sample_name}"-female_nonbleached_44
  elif [ "${sample_name}" == "P05" ]
  then
    sample_name="${sample_name}"-female_bleached_44
  elif [ "${sample_name}" == "P06" ]
  then
    sample_name="${sample_name}"-male_bleached_K5
  elif [ "${sample_name}" == "P07" ]
  then
    sample_name="${sample_name}"-male_bleached_K5
  elif [ "${sample_name}" == "P08" ]
  then
    sample_name="${sample_name}"-female_bleached_K5
  elif [ "${sample_name}" == "P09" ]
  then
    sample_name="${sample_name}"-female_bleached_K5
  elif [ "${sample_name}" == "P10" ]
  then
    sample_name="${sample_name}"-female_nonbleached_K5
  elif [ "${sample_name}" == "P11" ]
  then
    sample_name="${sample_name}"-female_bleached_44
  elif [ "${sample_name}" == "P12" ]
  then
    sample_name="${sample_name}"-female_nonbleached_44
  elif [ "${sample_name}" == "P13" ]
  then
    sample_name="${sample_name}"-female_bleached_K5
  elif [ "${sample_name}" == "P14" ]
  then
    sample_name="${sample_name}"-female_bleached_K5
  fi
  # Run bowtie2 on each pair of FastQ files
  "${bt2}" \
  --rg-id "${sample_name}" \
  --rg SM:"${sample_name}" \
  --rg PL:Illumina \
  -x "${bt2_index_name}" \
  -1 "${fastq_array_R1[index]}" \
  -2 "${fastq_array_R2[index]}" \
  --threads="${threads}" \
  -S "${sample_name}".sam \
  1> "${sample_name}".stdout \
  2> "${sample_name}"bt2-mapping-results.txt

  # Create tab-delimited text file with read group info
  # Needed during samtools merge step
  printf "%s\t%s%s\t%s\t\n" "@RG" "${sample_name}" "SM:${sample_name}" "PL:Illumina" \
  >> rg.txt

  # Convert SAM to BAM
  "${samtools}" view \
  --threads "${threads}" \
  -bS "${sample_name}".sam \
  > "${sample_name}".bam

  # Sort BAM
  "${samtools}" sort \
  --threads "${threads}" \
  "${sample_name}".bam \
  -o "${sample_name}".sorted.bam

  # Run Picard to remove duplicate reads
  ## Sets maximum java heap size to 16GB
  java \
  -Xmx16g \
  -jar \
  "${picard}" MarkDuplicates \
  REMOVE_DUPLICATES=true \
  INPUT="${sample_name}".sorted.bam \
  OUTPUT="${sample_name}".sorted.dedup.bam \
  METRICS_FILE="${sample_name}"-picard_metrics.txt \
  VALIDATION_STRINGENCY=LENIENT

  # Index new BAM file
  "${samtools}" index \
  -@ "${threads}" \
  "${sample_name}".sorted.dedup.bam
done

# Merge deduplicated files
"${samtools}" merge \
--threads "${threads}" \
-rh rg.txt \
merged.bam \
*dedup.bam

# Index mergred BAM file
"${$samtools}" index \
-@ "${threads}" \
merge.bam

# Email me when finished
sed '/^Subject:/ s/ / porites_blastp JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
