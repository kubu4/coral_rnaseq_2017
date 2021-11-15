#!/bin/bash
## Job Name
#SBATCH --job-name=20210927_mcap_trinotate_GG-transcriptome
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=1-00:00:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210927_mcap_trinotate_GG-transcriptome


## Script for running BLASTx (using DIAMOND) to annotate
## mcap_cnidaria_transcriptome_v1.0.fasta assembly from 20210903 against SwissProt database.
## Output will be in standard BLAST output format 6.
## For use with Trinotate later on.

###################################################################################
# These variables need to be set by user

wd="$(pwd)"

timestamp=$(date +%Y%m%d)
species="mcap"

prefix="${timestamp}.${species}.trinotate"

# Paths to input/output files
## Non-working directory locations
blastp_out_dir="/gscratch/scrubbed/samwhite/outputs/20210922_mcap_transdecoder_GG-transcriptome/blastp_out"
blastx_out_dir="/gscratch/scrubbed/samwhite/outputs/20210924_mcap_diamond-blastx_Trinity-GG_transcriptome"
pfam_out_dir="/gscratch/scrubbed/samwhite/outputs/20210922_mcap_transdecoder_GG-transcriptome/pfam_out"
trinity_out_dir="/gscratch/srlab/sam/data/M_capitata/transcriptomes"
transdecoder_out_dir="/gscratch/scrubbed/samwhite/outputs/20210922_mcap_transdecoder_GG-transcriptome/mcap_cnidaria_transcriptome_v1.0.fasta.transdecoder_dir"



## New folders for working directory
rnammer_out_dir="${wd}/RNAmmer_out"
signalp_out_dir="${wd}/signalp_out"
tmhmm_out_dir="${wd}/tmhmm_out"


blastp_out="${blastp_out_dir}/mcap_cnidaria_transcriptome_v1.0.fasta.blastp.outfmt6"
blastx_out="${blastx_out_dir}/mcap_cnidaria_transcriptome_v1.0.blastx.outfmt6.blastx.outfmt6"
pfam_out="${pfam_out_dir}/mcap_cnidaria_transcriptome_v1.0.fasta.pfam.domtblout"
lORFs_pep="${transdecoder_out_dir}/longest_orfs.pep"
rnammer_out="${rnammer_out_dir}/mcap_cnidaria_transcriptome_v1.0.fasta.rnammer.gff"
signalp_out="${signalp_out_dir}/signalp.out"
tmhmm_out="${tmhmm_out_dir}/tmhmm.out"
trinity_fasta="${trinity_out_dir}/mcap_cnidaria_transcriptome_v1.0.fasta"
trinity_gene_map="${trinity_out_dir}/mcap_cnidaria_transcriptome_v1.0.fasta.gene_trans_map"
trinotate_report="${wd}/${prefix}.trinotate_annotation_report.txt"



# Paths to programs
rnammer_dir="/gscratch/srlab/programs/RNAMMER-1.2"
rnammer="${rnammer_dir}/rnammer"
signalp_dir="/gscratch/srlab/programs/signalp-4.1"
signalp="${signalp_dir}/signalp"
tmhmm_dir="/gscratch/srlab/programs/tmhmm-2.0c/bin"
tmhmm="${tmhmm_dir}/tmhmm"
trinotate_dir="/gscratch/srlab/programs/Trinotate-v3.1.1"
trinotate="${trinotate_dir}/Trinotate"
trinotate_rnammer="${trinotate_dir}/util/rnammer_support/RnammerTranscriptome.pl"
trinotate_GO="${trinotate_dir}/util/extract_GO_assignments_from_Trinotate_xls.pl"
trinotate_features="${trinotate_dir}/util/Trinotate_get_feature_name_encoding_attributes.pl"
trinotate_sqlite_db="Trinotate.sqlite"

###################################################################################

# Exit if something fails
set -e

# Load Python Mox module for Python module availability
module load intel-python3_2017

# Make output directories
mkdir "${rnammer_out_dir}" "${signalp_out_dir}" "${tmhmm_out_dir}"

# Copy sqlite database template

cp ${trinotate_dir}/admin/Trinotate.sqlite .

echo "Running SignalP..."
echo ""
# Run signalp
${signalp} \
-f short \
-n "${signalp_out}" \
${lORFs_pep}
echo "SignalP completed."
echo ""

echo "Starting tmhmm..."
echo ""
# Run tmHMM
${tmhmm} \
--short \
< ${lORFs_pep} \
> "${tmhmm_out}"
echo "tmhmmm completed."
echo ""

# Run RNAmmer
echo "Starting RNAmmer..."
echo ""
cd "${rnammer_out_dir}" || exit
${trinotate_rnammer} \
--transcriptome ${trinity_fasta} \
--path_to_rnammer ${rnammer}
cd "${wd}" || exit
echo "RNAmmer completed."
echo ""

# Run Trinotate
## Load transcripts and coding regions into database
echo "Loading transcriptomics into sqlite database..."
echo ""
${trinotate} \
${trinotate_sqlite_db} \
init \
--gene_trans_map "${trinity_gene_map}" \
--transcript_fasta "${trinity_fasta}" \
--transdecoder_pep "${lORFs_pep}"
echo "Finished loading transcriptomics into sqlite database."

## Load BLAST homologies
"${trinotate}" \
"${trinotate_sqlite_db}" \
LOAD_swissprot_blastp \
"${blastp_out}"

"${trinotate}" \
"${trinotate_sqlite_db}" \
LOAD_swissprot_blastx \
"${blastx_out}"

## Load Pfam
"${trinotate}" \
"${trinotate_sqlite_db}" \
LOAD_pfam \
"${pfam_out}"

## Load transmembrane domains
"${trinotate}" \
"${trinotate_sqlite_db}" \
LOAD_tmhmm \
"${tmhmm_out}"

## Load signal peptides
"${trinotate}" \
"${trinotate_sqlite_db}" \
LOAD_signalp \
"${signalp_out}"

## Load RNAmmer
"${trinotate}" \
"${trinotate_sqlite_db}" \
LOAD_rnammer \
"${rnammer_out}"

## Creat annotation report
"${trinotate}" \
"${trinotate_sqlite_db}" \
report \
> "${trinotate_report}"

# Extract GO terms from annotation report
"${trinotate_GO}" \
--Trinotate_xls "${trinotate_report}" \
-G \
--include_ancestral_terms \
> "${prefix}".go_annotations.txt

# Make transcript features annotation map
"${trinotate_features}" \
"${trinotate_report}" \
> "${prefix}".annotation_feature_map.txt


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
echo "Logging system \$PATH..."
echo ""
{
date
echo ""
echo "System PATH for $SLURM_JOB_ID"
echo ""
printf "%0.s-" {1..10}
echo "${PATH}" | tr : \\n
} >> system_path.log
echo ""
echo "Finished logging system \$PATH."
