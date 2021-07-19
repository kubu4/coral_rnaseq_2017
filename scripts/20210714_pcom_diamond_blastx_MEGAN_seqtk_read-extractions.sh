#!/bin/bash
## Job Name
#SBATCH --job-name=20210714_pcom_diamond_blastx_MEGAN_seqtk_read-extractions
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=5-00:00:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210714_pcom_diamond_blastx_MEGAN_read-extractions



###################################################################################
# These variables need to be set by user

## Assign Variables

# Set number of CPUs to use
threads=28

# Paths to programs
seqtk="/gscratch/srlab/programs/seqtk-1.3/seqtk"
samtools="/gscratch/srlab/programs/samtools-1.10/samtools"

# Input/output files
fastq_dir="/gscratch/scrubbed/samwhite/data/P_compressa/RNAseq/"
R1_suffix=megan_R1.fq
R2_suffix=megan_R2.fq

# Programs associative array
declare -A programs_array
programs_array=(
[seqtk]="${seqtk}" \
[samtools_index]="${samtools} index" \
[samtools_sort]="${samtools} sort" \
[samtools_view]="${samtools} view" \
)
###################################################################################


# Index FastA files
for fasta in *.fasta
do
    ${samtools} faidx ${fasta}
done


for fai in *READ1*.fai
do
  filename=$(basename ${fai} ".fasta.fai")

  # Extract sequence IDs
  awk '{print $1}' >> ${filename}.seqtk.read_id.list

  # Extract reads with matching IDs
  for fastq in ${fastq_dir}*READ1*.fq.gz
    do
      echo ""
      echo "Generating checksum for ${fastq}..."
      md5sum ${fastq} >> input_fastq_checksums.md5
      echo "Checksum completed."
      echo ""
      echo "Extracting reads from ${fastq}..."
      ${programs_array[seqtk]} subseq ${fastq} ${filename}.seqtk.read_id.list >> ${filename}.${R1_suffix}
      echo "Read extraction complete for ${fastq}."
      echo ""
    done
done

for fai in *READ2*.fai
do
  filename=$(basename ${fai} ".fasta.fai")

  # Extract sequence IDs
  awk '{print $1}' >> ${filename}.seqtk.read_id.list

  # Extract reads with matching IDs
  for fastq in ${fastq_dir}*READ2*.fq.gz
    do
      echo ""
      echo "Generating checksum for ${fastq}..."
      md5sum ${fastq} >> input_fastq_checksums.md5
      echo "Checksum completed."
      echo ""
      echo "Extracting reads from ${fastq}..."
      ${programs_array[seqtk]} subseq ${fastq} ${filename}.seqtk.read_id.list >> ${filename}.${R2_suffix}
      echo "Read extraction complete for ${fastq}."
      echo ""
    done
done

# Generate checksums for all files.
for file in *
do
  md5sum ${file} >> checksums.md5
done

#######################################################################################################

# Capture program options
if [[ "${#programs_array[@]}" -gt 0 ]]; then
  echo "Logging program options..."
  for program in "${!programs_array[@]}"
  do
    {
    echo "Program options for ${program}: "
    echo ""
    # Handle samtools help menus
    if [[ "${program}" == "samtools_index" ]] \
    || [[ "${program}" == "samtools_sort" ]] \
    || [[ "${program}" == "samtools_view" ]]
    then
      ${programs_array[$program]}

    # Handle DIAMOND BLAST menu
    elif [[ "${program}" == "diamond" ]]; then
      ${programs_array[$program]} help

    # Handle NCBI BLASTx menu
    elif [[ "${program}" == "blastx" ]]; then
      ${programs_array[$program]} -help
    fi
    ${programs_array[$program]} -h
    echo ""
    echo ""
    echo "----------------------------------------------"
    echo ""
    echo ""
  } &>> program_options.log || true

    # If MultiQC is in programs_array, copy the config file to this directory.
    if [[ "${program}" == "multiqc" ]]; then
      cp --preserve ~/.multiqc_config.yaml multiqc_config.yaml
    fi
  done
fi


# Document programs in PATH (primarily for program version ID)
{
date
echo ""
echo "System PATH for $SLURM_JOB_ID"
echo ""
printf "%0.s-" {1..10}
echo "${PATH}" | tr : \\n
