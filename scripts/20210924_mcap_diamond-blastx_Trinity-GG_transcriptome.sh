#!/bin/bash
## Job Name
#SBATCH --job-name=20210924_mcap_diamond-blastx_Trinity-GG_transcriptome
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=01-080:00:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210924_mcap_diamond-blastx_Trinity-GG_transcriptome


## Script for running BLASTx (using DIAMOND) to annotate
## mcap_cnidaria_transcriptome_v1.0.fasta assembly from 20210903 against SwissProt database.
## Output will be in standard BLAST output format 6.
## For use with Trinotate later on.

###################################################################################
# These variables need to be set by user

threads=28

# Programs array
declare -A programs_array
programs_array=(
[diamond]="/gscratch/srlab/programs/diamond-0.9.29/diamond"
)

# Transcriptomes arrays
transcriptomes_dir="/gscratch/srlab/sam/data/M_capitata/transcriptomes"
transcriptome="${transcriptomes_dir}/mcap_cnidaria_transcriptome_v1.0.fasta"

# DIAMOND UniProt database
dmnd=/gscratch/srlab/blastdbs/uniprot_sprot_20200123/uniprot_sprot.dmnd

###################################################################################

# Exit script if any command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017

# Generate checksums for reference
md5sum "${transcriptome}">> fasta.checksums.md5

# Strip leading path and extensions
no_path="${transcriptome##*/}"
no_ext="${no_path%.*}"

# Run DIAMOND with blastx
# Output format 6 produces a standard BLAST tab-delimited file
${programs_array[diamond]} blastx \
--db ${dmnd} \
--query "${transcriptome}" \
--out "${no_ext}".blastx.outfmt6 \
--long-reads \
--outfmt 6 \
--evalue 1e-4 \
--max-target-seqs 1 \
--block-size 15.0 \
--index-chunks 4


###################################################################################

# Capture program options
if [[ "${#programs_array[@]}" -gt 0 ]]; then
  echo "Logging program options..."
  for program in "${!programs_array[@]}"
  do
    {
    echo "Program options for ${program}: "
    echo ""
    # Handle samtools/bcftools help menus
    if [[ "${program}" == "samtools_index" ]] \
    || [[ "${program}" == "samtools_sort" ]] \
    || [[ "${program}" == "samtools_view" ]] \
    || [[ "${program}" == "bcftools_call" ]] \
    || [[ "${program}" == "bcftools_index" ]] \
    || [[ "${program}" == "bcftools_mpileup" ]] \
    || [[ "${program}" == "bcftools_view" ]]
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
  echo "Finished logging programs options."
  echo ""
fi


# Document programs in PATH (primarily for program version ID)
echo "Logging system $PATH..."
{
date
echo ""
echo "System PATH for $SLURM_JOB_ID"
echo ""
printf "%0.s-" {1..10}
echo "${PATH}" | tr : \\n
} >> system_path.log
echo "Finished logging system $PATH."