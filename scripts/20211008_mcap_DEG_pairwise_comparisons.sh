#!/bin/bash

# This is a script to identify differentially expressed genes (DEGs) in M.captita
# which has been taxonomically selected for all Cnidaria reads, using pairwise comparisions.

# Script will run Trinity's builtin differential gene expression analysis using:
# - Salmon alignment-free transcript abundance estimation
# - edgeR
# Cutoffs of 2-fold difference in expression and FDR of <=0.05.

###################################################################################
# These variables need to be set by user
fastq_dir="/home/sam/data/M_capitata/RNAseq"
fasta_prefix="Trinity-GG"
transcriptome_dir="/home/sam/data/M_capitata/transcriptomes"
trinotate_feature_map="${transcriptome_dir}/20211009.mcap.trinotate.annotation_feature_map.txt"
go_annotations="${transcriptome_dir}/20211009.mcap.trinotate.go_annotations.txt"

# Array of the various comparisons to evaluate
# Each condition in each comparison should be separated by a "-"
comparisons_array=(
bleached_non-bleached \
44_k4 \
bleached-k4_non-bleached-k4 \
bleached-44_non-bleached-44 \
bleached-44_bleached-k4 \
non-bleached-44_non-bleached-k4
)

# Functions
# Expects input (i.e. "$1") to be in the following format:
# e.g. 4R041-L6-P01-AGTCAA-READ1-Sequences.txt.gz_val_1.fq.gz
get_seq_index () { seq_index=$(echo "$1" | awk -F "-" '{print $4}'); }

#programs
trinity_home=/home/shared/Trinityrnaseq-v2.8.5
trinity_annotate_matrix="${trinity_home}/Analysis/DifferentialExpression/rename_matrix_feature_identifiers.pl"
trinity_abundance=${trinity_home}/util/align_and_estimate_abundance.pl
trinity_matrix=${trinity_home}/util/abundance_estimates_to_matrix.pl
trinity_DE=${trinity_home}/Analysis/DifferentialExpression/run_DE_analysis.pl
diff_expr=${trinity_home}/Analysis/DifferentialExpression/analyze_diff_expr.pl
trinity_tpm_length=${trinity_home}/util/misc/TPM_weighted_gene_length.py

###################################################################################

# Exit script if any command fails
set -e

wd="$(pwd)"
threads=24


## Designate input file locations
transcriptome="${transcriptome_dir}/${fasta_prefix}.fasta"
fasta_seq_lengths="${transcriptome_dir}/${fasta_prefix}.fasta.seq_lens"
gene_map="${transcriptome_dir}/${fasta_prefix}.fasta.gene_trans_map"
transcriptome="${transcriptome_dir}/${fasta_prefix}.fasta"


# Standard output/error files
diff_expr_stdout="diff_expr_stdout.txt"
diff_expr_stderr="diff_expr_stderr.txt"
matrix_stdout="matrix_stdout.txt"
matrix_stderr="matrix_stderr.txt"
salmon_stdout="salmon_stdout.txt"
salmon_stderr="salmon_stderr.txt"
tpm_length_stdout="tpm_length_stdout.txt"
tpm_length_stderr="tpm_length_stderr.txt"
trinity_DE_stdout="trinity_DE_stdout.txt"
trinity_DE_stderr="trinity_DE_stderr.txt"

edgeR_dir=""

# Loop through each comparison
# Will create comparison-specific direcctories and copy
# appropriate FastQ files for each comparison.

# After file transfer, will create necessary sample list file for use
# by Trinity for running differential gene expression analysis and GO enrichment.
for comparison in "${!comparisons_array[@]}"
do

  # Assign variables
  cond1_count=0
  cond2_count=0
  comparison=${comparisons_array[${comparison}]}
  comparison_dir=${wd}/${comparison}/
  salmon_gene_matrix=${comparison_dir}/salmon.gene.TMM.EXPR.matrix
  salmon_iso_matrix=${comparison_dir}/salmon.isoform.TMM.EXPR.matrix
  samples=${comparison_dir}${comparison}.samples.txt

  # Reset arrays
  cond1_array=()
  cond2_array=()

  # Extract each comparison from comparisons array
  # Conditions must be separated by a "_"
  cond1=$(echo "${comparison}" | awk -F"_" '{print $1}')
  cond2=$(echo "${comparison}" | awk -F"_" '{print $2}')


  mkdir --parents "${comparison}"

  cd "${comparison}" || exit

  # Series of if statements to identify which FastQ files to rsync to working directory
  if [[ "${comparison}" == "44_k4" ]]; then
    for fastq in ${fastq_dir}*.fq.gz
    do
        get_seq_index "${fastq}"
        # These are Site 44 indices
        if [[ "${seq_index}" == "GTCCGC" \
        || "${seq_index}" == "GAGTGG" \
        || "${seq_index}" == "GTTTCG" \
        || "${seq_index}" == "TAGCTT" \
        || "${seq_index}" == "ATCACG" \
        || "${seq_index}" == "GCCAAT" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond1_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."

        # These are Site K4 indices
        elif [[ "${seq_index}" == "GGCTAC" \
        || "${seq_index}" == "ACTGAT" \
        || "${seq_index}" == "AGTCAA" \
        || "${seq_index}" == "AGTTCC" \
        || "${seq_index}" == "CTTGTA" \
        || "${seq_index}" == "ATGTCA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond2_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."
        fi
    done
  fi

  if [[ "${comparison}" == "bleached_non-bleached" ]]; then
    for fastq in ${fastq_dir}*.fq.gz
    do
        get_seq_index "${fastq}"
        # These are bleached indices.
        if [[ "${seq_index}" == "GTCCGC" \
        || "${seq_index}" == "GTTTCG" \
        || "${seq_index}" == "ATCACG" \
        || "${seq_index}" == "GGCTAC" \
        || "${seq_index}" == "AGTTCC" \
        || "${seq_index}" == "ATGTCA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond1_array+=("${fastq}")


          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."

        # These are non-bleached indices
        elif [[ "${seq_index}" == "GAGTGG" \
        || "${seq_index}" == "TAGCTT" \
        || "${seq_index}" == "GCCAAT" \
        || "${seq_index}" == "ACTGAT" \
        || "${seq_index}" == "AGTCAA" \
        || "${seq_index}" == "CTTGTA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond2_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."
        fi
    done
  fi

  if [[ "${comparison}" == "bleached-k4_non-bleached-k4" ]]; then
    for fastq in ${fastq_dir}*.fq.gz
    do
        get_seq_index "${fastq}"
        # These are bleached k4 indices
        if [[ "${seq_index}" == "GGCTAC" \
        || "${seq_index}" == "AGTTCC" \
        || "${seq_index}" == "ATGTCA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond1_array+=("${fastq}")


          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."

        # These are non-bleached k4 indices.  
        elif [[ "${seq_index}" == "ACTGAT" \
        || "${seq_index}" == "AGTCAA" \
        || "${seq_index}" == "CTTGTA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond2_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."
        fi
    done
  fi

  if [[ "${comparison}" == "bleached-44_non-bleached-44" ]]; then
    for fastq in ${fastq_dir}*.fq.gz
    do
        get_seq_index "${fastq}"
        # These are bleached 44 indices
        if [[ "${seq_index}" == "GTCCGC" \
        || "${seq_index}" == "GTTTCG" \
        || "${seq_index}" == "ATCACG" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond1_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."

        # These are non-bleached 44 indices.  
        elif [[ "${seq_index}" == "GAGTGG" \
        || "${seq_index}" == "TAGCTT" \
        || "${seq_index}" == "GCCAAT" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond2_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."
        fi
    done
  fi

  if [[ "${comparison}" == "bleached-44_bleached-k4" ]]; then
    for fastq in ${fastq_dir}*.fq.gz
    do
        get_seq_index "${fastq}"
        # These are bleached 44 indices
        if [[ "${seq_index}" == "GTCCGC" \
        || "${seq_index}" == "GTTTCG" \
        || "${seq_index}" == "ATCACG" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond1_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."

        # These are bleached k4 indices.  
        elif [[ "${seq_index}" == "GGCTAC" \
        || "${seq_index}" == "AGTTCC" \
        || "${seq_index}" == "ATGTCA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond2_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."
        fi
    done
  fi

  if [[ "${comparison}" == "non-bleached-44_non-bleached-k4" ]]; then
    for fastq in ${fastq_dir}*.fq.gz
    do
        get_seq_index "${fastq}"
        # These are non-bleached 44 indices
        if  [[ "${seq_index}" == "GAGTGG" \
        || "${seq_index}" == "TAGCTT" \
        || "${seq_index}" == "GCCAAT" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond1_array+=("${fastq}")
          
          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."

        # These are non-bleached k4 indices.  
        elif [[ "${seq_index}" == "ACTGAT" \
        || "${seq_index}" == "AGTCAA" \
        || "${seq_index}" == "CTTGTA" ]]; then
          rsync --archive --verbose ${fastq} .

          # Get just filename for use in array
          fastq=$(basename ${fastq})

          # Add FastQ filename to array
          cond2_array+=("${fastq}")

          # Create list/checksums of FastQ files used
          echo ""
          echo "Generating checksum for ${fastq}."
          md5sum "${fastq}" | tee -a input_fastqs.md5
          echo ""
          echo "Finished generating checksum for ${fastq}."
        fi
    done
  fi


  # Loop to create sample list file
  # Sample file list is tab-delimited like this:

  # cond_A    cond_A_rep1    A_rep1_left.fq    A_rep1_right.fq
  # cond_A    cond_A_rep2    A_rep2_left.fq    A_rep2_right.fq
  # cond_B    cond_B_rep1    B_rep1_left.fq    B_rep1_right.fq
  # cond_B    cond_B_rep2    B_rep2_left.fq    B_rep2_right.fq



  # Increment by 2 to process next pair of FastQ files
  for (( i=0; i<${#cond1_array[@]} ; i+=2 ))
  do

    cond1_count=$((cond1_count+1))

    # Create tab-delimited samples file.
    printf "%s\t%s%02d\t%s\t%s\n" "${cond1}" "${cond1}_" "${cond1_count}" "${comparison_dir}${cond1_array[i]}" "${comparison_dir}${cond1_array[i+1]}" \
    >> "${samples}"
  done

  for (( i=0; i<${#cond2_array[@]} ; i+=2 ))
  do
    cond2_count=$((cond2_count+1))

    # Create tab-delimited samples file.
    printf "%s\t%s%02d\t%s\t%s\n" "${cond2}" "${cond2}_" "${cond2_count}" "${comparison_dir}${cond2_array[i]}" "${comparison_dir}${cond2_array[i+1]}" \
    >> "${samples}"
  done

  # Copy sample list file to transcriptome directory
  cp "${samples}" "${transcriptome_dir}"


  echo "Created ${comparison} sample list file."


  # Create directory/sample list for ${trinity_matrix} command
  trin_matrix_list=$(awk '{printf "%s%s", $2, "/quant.sf " }' "${samples}")


  # Determine transcript abundances using Salmon alignment-free
  # abundance estimate.
  ${trinity_abundance} \
  --output_dir "${comparison_dir}" \
  --transcripts ${transcriptome} \
  --seqType fq \
  --samples_file "${samples}" \
  --est_method salmon \
  --aln_method bowtie2 \
  --gene_trans_map "${gene_map}" \
  --prep_reference \
  --thread_count "${threads}" \
  1> "${comparison_dir}"${salmon_stdout} \
  2> "${comparison_dir}"${salmon_stderr}

  # Convert abundance estimates to matrix
  ${trinity_matrix} \
  --est_method salmon \
  --gene_trans_map ${gene_map} \
  --out_prefix salmon \
  --name_sample_by_basedir \
  ${trin_matrix_list} \
  1> ${matrix_stdout} \
  2> ${matrix_stderr}

  # Integrate Trinotate functional annotations
  "${trinity_annotate_matrix}" \
  "${trinotate_feature_map}" \
  salmon.gene.counts.matrix \
  > salmon.gene.counts.annotated.matrix


  # Generate weighted gene lengths
  "${trinity_tpm_length}" \
  --gene_trans_map "${gene_map}" \
  --trans_lengths "${fasta_seq_lengths}" \
  --TPM_matrix "${salmon_iso_matrix}" \
  > Trinity.gene_lengths.txt \
  2> ${tpm_length_stderr}

  # Differential expression analysis
  # Utilizes edgeR.
  # Needs to be run in same directory as transcriptome.
  cd ${transcriptome_dir} || exit
  ${trinity_DE} \
  --matrix "${comparison_dir}salmon.gene.counts.matrix" \
  --method edgeR \
  --samples_file "${samples}" \
  1> ${trinity_DE_stdout} \
  2> ${trinity_DE_stderr}

  mv edgeR* "${comparison_dir}"


  # Run differential expression on edgeR output matrix
  # Set fold difference to 2-fold (ie. -C 1 = 2^1)
  # P value <= 0.05
  # Has to run from edgeR output directory

  # Pulls edgeR directory name and removes leading ./ in find output
  # Using find is required because edgeR names directory using PID
  # and I don't know how to find that out
  cd "${comparison_dir}" || exit
  edgeR_dir=$(find . -type d -name "edgeR*" | sed 's%./%%')
  cd "${edgeR_dir}" || exit
  mv "${transcriptome_dir}/${trinity_DE_stdout}" .
  mv "${transcriptome_dir}/${trinity_DE_stderr}" .
  ${diff_expr} \
  --matrix "${salmon_gene_matrix}" \
  --samples "${samples}" \
  --examine_GO_enrichment \
  --GO_annots "${go_annotations}" \
  --include_GOplot \
  --gene_lengths "${comparison_dir}Trinity.gene_lengths.txt" \
  -C 1 \
  -P 0.05 \
  1> ${diff_expr_stdout} \
  2> ${diff_expr_stderr}



  cd "${wd}" || exit
done

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