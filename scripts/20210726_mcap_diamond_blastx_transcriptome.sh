#!/bin/bash
## Job Name
#SBATCH --job-name=20210726_mcap_diamond_blastx_transcriptome
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=0-08:00:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210726_mcap_diamond_blastx_transcriptome


## Script for running BLASTx (using DIAMOND) with
## M.capitata transcriptome for downstream taxonomic separation.
## Output will be in standard BLAST output format 6.

###################################################################################
# These variables need to be set by user

# Programs array
declare -A programs_array
programs_array=(
[diamond]="/gscratch/srlab/programs/diamond-2.0.4/diamond"
)

# Establish variables for more readable code
transcriptomes_dir=/gscratch/srlab/sam/data/M_capitata/transcriptomes

# Array transcriptome(s)
transcriptomes_array=(
"${transcriptomes_dir}"/Trinity.fasta \
)

# DIAMOND NCBI nr database
dmnd=/gscratch/srlab/blastdbs/ncbi-nr-20200924/nr.dmnd

###################################################################################

# Exit script if any command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017


for fasta in "${!transcriptomes_array[@]}"
do

  # Remove path from transcriptome using parameter substitution
  transcriptome_name="${transcriptomes_array[$fasta]##*/}"

  # Generate checksums for reference
  md5sum "${transcriptomes_array[$fasta]}">> fasta.checksum.md5

  # Run DIAMOND with blastx
  # Output format 6 produces a standard BLAST tab-delimited file
  ${programs_array[diamond]} blastx \
  --db ${dmnd} \
  --query "${transcriptomes_array[$fasta]}" \
  --out "${transcriptome_name}".blastx.daa \
  --long-reads \
  --outfmt 100 \
  --evalue 1e-4 \
  --max-target-seqs 1 \
  --block-size 8.0 \
  --index-chunks 1
done


###################################################################################

# Capture program options
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

echo ""
echo "Finished logging program options."
echo ""

echo ""
echo "Logging system PATH."
# Document programs in PATH (primarily for program version ID)
{
date
echo ""
echo "System PATH for $SLURM_JOB_ID"
echo ""
printf "%0.s-" {1..10}
echo "${PATH}" | tr : \\n
} >> system_path.log

echo "Finished logging system PATH"
