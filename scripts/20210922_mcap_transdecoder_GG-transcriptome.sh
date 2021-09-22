#!/bin/bash
## Job Name
#SBATCH --job-name=20200922_mcap_transdecoder_GG-transcriptome
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=8-00:00:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20200922_mcap_transdecoder_GG-transcriptome


###################################################################################
# These variables need to be set by user

## Assign Variables

# CPU threads
threads=40

# Set input file locations
transcriptome_dir="${transcriptome_dir}"
trinity_fasta="${transcriptome_dir}/Trinity-GG.fasta"
trinity_gene_map="${transcriptome_dir}/Trinity-GG.fasta.gene_trans_map"


# Capture trinity file name
trinity_fasta_name=${trinity_fasta##*/}



# Paths to input/output files
blastp_out_dir="${wd}/blastp_out"
transdecoder_out_dir="${wd}/${trinity_fasta_name}.transdecoder_dir"
pfam_out_dir="${wd}/pfam_out"
blastp_out="${blastp_out_dir}/${trinity_fasta_name}.blastp.outfmt6"
pfam_out="${pfam_out_dir}/${trinity_fasta_name}.pfam.domtblout"
lORFs_pep="${transdecoder_out_dir}/longest_orfs.pep"
pfam_db="/gscratch/srlab/programs/Trinotate-v3.1.1/admin/Pfam-A.hmm"
sp_db="/gscratch/srlab/programs/Trinotate-v3.1.1/admin/uniprot_sprot.pep"



# Paths to programs
blast_dir="/gscratch/srlab/programs/ncbi-blast-2.8.1+/bin"
blastp="${blast_dir}/blastp"
hmmer_dir="/gscratch/srlab/programs/hmmer-3.2.1/src"
hmmscan="${hmmer_dir}/hmmscan"
transdecoder_dir="/gscratch/srlab/programs/TransDecoder-v5.5.0"
transdecoder_lORFs="${transdecoder_dir}/TransDecoder.LongOrfs"
transdecoder_predict="${transdecoder_dir}/TransDecoder.Predict"

# Programs associative array
declare -A programs_array
programs_array=(
[hmmscan]="${hmmscan}" \
[blastp]="${blastp}" \
[transdecoder_lORFs="${transdecoder_lORFs}" \
[transdecoder_predict]="${transdecoder_predict}"
)

###################################################################################################

# Exit script if a command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017


# Set workind directory as current directory
wd="$(pwd)"




# Capture FastA MD5 checksum for future reference
md5sum "${trinity_fasta}" >> "${trinity_fasta_name}".checksum.md5

# Make output directories
mkdir "${blastp_out_dir}"
mkdir "${pfam_out_dir}"

# Extract long open reading frames
"${transdecoder_lORFs}" \
--gene_trans_map "${trinity_gene_map}" \
-t "${trinity_fasta}"

# Run blastp on long ORFs
"${blastp}" \
-query "${lORFs_pep}" \
-db "${sp_db}" \
-max_target_seqs 1 \
-outfmt 6 \
-evalue 1e-5 \
-num_threads ${threads} \
> "${blastp_out}"

# Run pfam search
"${hmmscan}" \
--cpu ${threads} \
--domtblout "${pfam_out}" \
"${pfam_db}" \
"${lORFs_pep}"

# Run Transdecoder with blastp and Pfam results
"${transdecoder_predict}" \
-t "${trinity_fasta}" \
--retain_pfam_hits "${pfam_out}" \
--retain_blastp_hits "${blastp_out}"

#######################################################################################################

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