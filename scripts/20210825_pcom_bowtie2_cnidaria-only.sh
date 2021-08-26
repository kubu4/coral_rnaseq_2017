#!/bin/bash
## Job Name
#SBATCH --job-name=20210825_pcom_bowtie2_cnidaria-only
## Allocation Definition
#SBATCH --account=srlab
#SBATCH --partition=srlab
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=5-00:00:00
## Memory per node
#SBATCH --mem=500G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210825_pcom_bowtie2_cnidaria-only

## Bowtie2 transcriptome indexing and alignment of P.compressa RNAseq to P.compressa
## cindaria-only transcriptome.

## Expects FastQ input filenames to match *READ[12]*.fq.gz


###################################################################################
# These variables need to be set by user

## Assign Variables

# Set number of CPUs to use
threads=28

# Index name for Hisat2 use
# Needs to match index naem used in previous Hisat2 indexing step
transcriptome_index_name="Cnidaria_MEGAN-extractions"

# Set output filename
sample_name="20210825-pcom-bowtie2"

# Paths to programs
bowtie2_dir="/gscratch/srlab/programs/bowtie2-2.4.2-linux-x86_64"
bowtie2="${bowtie2_dir}/bowtie2"
bowtie2_build="${bowtie2_dir}/bowtie2-build"
samtools="/gscratch/srlab/programs/samtools-1.10/samtools"


# Input/output files
transcriptome_index_dir="/gscratch/srlab/sam/data/P_compressa/transcritpomes"
fastq_dir="/gscratch/srlab/sam/data/P_compressa/RNAseq/"


# Programs associative array
declare -A programs_array
programs_array=(
[bowtie2]="${bowtie2}" \
[bowtie2_build]="${bowtie2_build}" \
[samtools_index]="${samtools} index" \
[samtools_sort]="${samtools} sort" \
[samtools_view]="${samtools} view"
)


###################################################################################################

# Exit script if any command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017

## Inititalize arrays
fastq_array_R1=()
fastq_array_R2=()

# Copy Hisat2 genome index files
rsync -av "${genome_index_dir}"/${genome_index_name}*.ht2 .

# Create array of fastq R1 files
# and generated MD5 checksums file.
for fastq in "${fastq_dir}"*READ1*.gz
do
  fastq_array_R1+=("${fastq}")
  echo "Generating checksum for ${fastq}..."
  md5sum "${fastq}" >> input_fastqs_checksums.md5
  echo "Checksum for ${fastq} completed."
  echo ""
done

# Create array of fastq R2 files
for fastq in "${fastq_dir}"*READ2*.gz
do
  fastq_array_R2+=("${fastq}")
  echo "Generating checksum for ${fastq}..."
  md5sum "${fastq}" >> input_fastqs_checksums.md5
  echo "Checksum for ${fastq} completed."
  echo ""
done

# Create comma-separated lists of FastQs for Hisat2
printf -v joined_R1 '%s,' "${fastq_array_R1[@]}"
fastq_list_R1=$(echo "${joined_R1%,}")

printf -v joined_R2 '%s,' "${fastq_array_R2[@]}"
fastq_list_R2=$(echo "${joined_R2%,}")


# Hisat2 alignments
"${programs_array[hisat2]}" \
-x "${genome_index_name}" \
-1 "${fastq_list_R1}" \
-2 "${fastq_list_R2}" \
-S "${sample_name}".sam \
2> "${sample_name}"_hisat2.err

# Sort SAM files, convert to BAM, and index
${programs_array[samtools_view]} \
-@ "${threads}" \
-Su "${sample_name}".sam \
| ${programs_array[samtools_sort]} - \
-@ "${threads}" \
-o "${sample_name}".sorted.bam
${programs_array[samtools_index]} "${sample_name}".sorted.bam


# Delete unneccessary index files
rm "${genome_index_name}"*.ht2

# Delete unneded SAM files
rm ./*.sam

# Generate checksums
for file in *
do
  md5sum "${file}" >> checksums.md5
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
} >> system_path.log