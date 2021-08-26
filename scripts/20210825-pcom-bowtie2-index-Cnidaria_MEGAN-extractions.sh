#!/bin/bash
## Job Name
#SBATCH --job-name=20210825-pcom-bowtie2-index-Cnidaria_MEGAN-extractions
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
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210825-pcom-bowtie2-index-Cnidaria_MEGAN-extractions

## Script using Bowtie2 to build a transcriptome index for cnidaria-only P.compressa transcriptome.


###################################################################################
# These variables need to be set by user

## Assign Variables

# Set number of CPUs to use
threads=40

# Set bowtie2 index name
transcriptome_index_name="pcom-Cnidaria_MEGAN-extractions"

# Paths to programs
bowtie2_dir="/gscratch/srlab/programs/bowtie2-2.4.2-linux-x86_64"
bowtie2_build="${bowtie2_dir}/bowtie2-build"

# Input/output files
transcriptome_dir="/gscratch/srlab/sam/data/P_compressa/transcriptomes"
transcriptome_fasta="${transcriptome_dir}/Cnidaria_MEGAN-extractions.fasta"


# Programs associative array
declare -A programs_array
programs_array=(
[bowtie2_build]="${bowtie2_build}"
)


###################################################################################################

# Exit script if any command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017

# Build bowtie2 reference index
"${programs_array[bowtie2_build]}" \
"${transcriptome_fasta}" \
"${transcriptome_index_name}" \
-p "${threads}" \
2> bowtie2_build.err

# Generate checksums for all files
md5sum * >> checksums.md5

# Copy bowtie2 index files to my data directory for later use
rsync -av "${transcriptome_index_name}"*.bt2 "${transcriptome_dir}"


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