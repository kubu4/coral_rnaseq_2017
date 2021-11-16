#!/bin/bash
## Job Name
#SBATCH --job-name=20211015_mcap_DEG_pairwise_comparisons
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=0-18:00:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20211015_mcap_DEG_pairwise_comparisons

# This is a script to identify differentially expressed genes (DEGs) in M.captita
# which has been taxonomically selected for all Cnidaria reads, using pairwise comparisions.

# In essence, this is a re-run on 20211008_mcap_DEG_pairwise_comparisons.sh. However, this run
# uses more detailed sample lists to help with Emma's analysis.

# Script will run Trinity's builtin differential gene expression analysis using:
# - Salmon alignment-free transcript abundance estimation
# - edgeR
# Cutoffs of 2-fold difference in expression and FDR of <=0.05.

###################################################################################
# These variables need to be set by user
fastq_dir="/gscratch/srlab/sam/data/M_capitata/RNAseq/"
fasta_prefix="mcap_cnidaria_transcriptome_v1.0"
transcriptome_dir="/gscratch/srlab/sam/data/M_capitata/transcriptomes"
trinotate_feature_map="${transcriptome_dir}/20211115.mcap.trinotate.annotation_feature_map.txt"
go_annotations="${transcriptome_dir}/20211115.mcap.trinotate.go_annotations.txt"

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

# Extract sequencing index from FastQ filename
# Expects input (i.e. "$1") to be in the following format:
# e.g. 4R041-L6-P01-AGTCAA-READ1-Sequences.txt.gz_val_1.fq.gz
get_seq_index () { seq_index=$(echo "$1" | awk -F "-" '{print $4}'); }

# Gets sampling site based off of sequencing index from get_seq_index function.
get_site () {
  # These are Site 44 indices
  if [[ "${seq_index}" == "GTCCGC" \
  || "${seq_index}" == "GAGTGG" \
  || "${seq_index}" == "GTTTCG" \
  || "${seq_index}" == "TAGCTT" \
  || "${seq_index}" == "ATCACG" \
  || "${seq_index}" == "GCCAAT" ]]; then

    # Set sample site
    site="44"
  
  # These are Site K4 indices
  elif [[ "${seq_index}" == "GGCTAC" \
  || "${seq_index}" == "ACTGAT" \
  || "${seq_index}" == "AGTCAA" \
  || "${seq_index}" == "AGTTCC" \
  || "${seq_index}" == "CTTGTA" \
  || "${seq_index}" == "ATGTCA" ]]; then

    # Set sample site
    site="k4"
  fi
}

# Gets bleaching status based off of sequencing index from get_seq_index function.
get_bleach_info () {
  # These are bleached indices
  if [[ "${seq_index}" == "GTCCGC" \
  || "${seq_index}" == "GTTTCG" \
  || "${seq_index}" == "ATCACG" \
  || "${seq_index}" == "GGCTAC" \
  || "${seq_index}" == "AGTTCC" \
  || "${seq_index}" == "ATGTCA" ]]; then

    # Set bleach status
    bleach_status="bleached"
  
  elif [[ "${seq_index}" == "GAGTGG" \
  || "${seq_index}" == "TAGCTT" \
  || "${seq_index}" == "GCCAAT" \
  || "${seq_index}" == "ACTGAT" \
  || "${seq_index}" == "AGTCAA" \
  || "${seq_index}" == "CTTGTA" ]]; then

    # Set bleach status
    bleach_status="non-bleached"
  fi
}

#programs
trinity_home=/gscratch/srlab/programs/trinityrnaseq-v2.9.0
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
threads=28


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

  # Note: These sample list files have been manually edited to
  # properly increment sample replicates. However, they were originally
  # created programmaticaly and have been double-checked for accuracy.
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
    for fastq in "${fastq_dir}"*.fq.gz
    do

      # Retrieve sequencing index
      get_seq_index "${fastq}"

      # These are Site 44 indices
      if [[ "${seq_index}" == "GTCCGC" \
      || "${seq_index}" == "GAGTGG" \
      || "${seq_index}" == "GTTTCG" \
      || "${seq_index}" == "TAGCTT" \
      || "${seq_index}" == "ATCACG" \
      || "${seq_index}" == "GCCAAT" ]]; then

        # Copy files to current directory
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

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


        # Copy files to current directory
        rsync --archive --verbose "${fastq}" .


        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond2_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""
      fi
    done
  fi

  if [[ "${comparison}" == "bleached_non-bleached" ]]; then
    for fastq in "${fastq_dir}"*.fq.gz
    do
      # Retrieve sequencing index
      get_seq_index "${fastq}"
      # These are bleached indices.
      if [[ "${seq_index}" == "GTCCGC" \
      || "${seq_index}" == "GTTTCG" \
      || "${seq_index}" == "ATCACG" \
      || "${seq_index}" == "GGCTAC" \
      || "${seq_index}" == "AGTTCC" \
      || "${seq_index}" == "ATGTCA" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond1_array+=("${fastq}")


        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""

      # These are non-bleached indices
      elif [[ "${seq_index}" == "GAGTGG" \
      || "${seq_index}" == "TAGCTT" \
      || "${seq_index}" == "GCCAAT" \
      || "${seq_index}" == "ACTGAT" \
      || "${seq_index}" == "AGTCAA" \
      || "${seq_index}" == "CTTGTA" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond2_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""
      fi
    done
  fi

  if [[ "${comparison}" == "bleached-k4_non-bleached-k4" ]]; then
    for fastq in "${fastq_dir}"*.fq.gz
    do
      # Retrieve sequencing index
      get_seq_index "${fastq}"
      # These are bleached k4 indices
      if [[ "${seq_index}" == "GGCTAC" \
      || "${seq_index}" == "AGTTCC" \
      || "${seq_index}" == "ATGTCA" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond1_array+=("${fastq}")


        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""

      # These are non-bleached k4 indices.  
      elif [[ "${seq_index}" == "ACTGAT" \
      || "${seq_index}" == "AGTCAA" \
      || "${seq_index}" == "CTTGTA" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond2_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""
      fi
    done
  fi

  if [[ "${comparison}" == "bleached-44_non-bleached-44" ]]; then
    for fastq in "${fastq_dir}"*.fq.gz
    do
      # Retrieve sequencing index
      get_seq_index "${fastq}"
      # These are bleached 44 indices
      if [[ "${seq_index}" == "GTCCGC" \
      || "${seq_index}" == "GTTTCG" \
      || "${seq_index}" == "ATCACG" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond1_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""

      # These are non-bleached 44 indices.  
      elif [[ "${seq_index}" == "GAGTGG" \
      || "${seq_index}" == "TAGCTT" \
      || "${seq_index}" == "GCCAAT" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond2_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""
      fi
    done
  fi

  if [[ "${comparison}" == "bleached-44_bleached-k4" ]]; then
    for fastq in "${fastq_dir}"*.fq.gz
    do
      # Retrieve sequencing index
      get_seq_index "${fastq}"
      # These are bleached 44 indices
      if [[ "${seq_index}" == "GTCCGC" \
      || "${seq_index}" == "GTTTCG" \
      || "${seq_index}" == "ATCACG" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond1_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""

      # These are bleached k4 indices.  
      elif [[ "${seq_index}" == "GGCTAC" \
      || "${seq_index}" == "AGTTCC" \
      || "${seq_index}" == "ATGTCA" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond2_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""
      fi
    done
  fi

  if [[ "${comparison}" == "non-bleached-44_non-bleached-k4" ]]; then
    for fastq in "${fastq_dir}"*.fq.gz
    do
      # Retrieve sequencing index
      get_seq_index "${fastq}"
      # These are non-bleached 44 indices
      if  [[ "${seq_index}" == "GAGTGG" \
      || "${seq_index}" == "TAGCTT" \
      || "${seq_index}" == "GCCAAT" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond1_array+=("${fastq}")
        
        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""

      # These are non-bleached k4 indices.  
      elif [[ "${seq_index}" == "ACTGAT" \
      || "${seq_index}" == "AGTCAA" \
      || "${seq_index}" == "CTTGTA" ]]; then
        rsync --archive --verbose "${fastq}" .

        # Get just filename for use in array
        fastq=$(basename "${fastq}")

        # Add FastQ filename to array
        cond2_array+=("${fastq}")

        # Create list/checksums of FastQ files used
        echo ""
        echo "Generating checksum for ${fastq}."
        md5sum "${fastq}" | tee -a input_fastqs.md5
        echo "Finished generating checksum for ${fastq}."
        echo ""
      fi
    done
  fi

  # Copy ${samples} file to current directory (to have as reference)
  cp "${transcriptome_dir}"/"${comparison}.samples.txt" .


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


# Begin "flattening" Trinity edgeR GOseq enrichment format
# so each line contains a single gene/transcript ID
# and associated GO term


# Enable globstar for recursive searching
# used in for loop below for finding GOseq enrichment files
shopt -s globstar

output_file=""

# Input file
## Expects Trinity edgeR GOseq enrichment format:
## category	over_represented_pvalue	under_represented_pvalue	numDEInCat	numInCat	term	ontology	over_represented_FDR	go_term	gene_ids
## Field 10 (gene_ids) contains comma separated gene_ids that fall in the given GO term in the "category" column

for goseq in **/*UP.subset*.enriched
do
	# Capture path to file
	dir=${goseq%/*}

	cd "${dir}" || exit

	tmp_file=$(mktemp)

	# Count lines in file
  linecount=$(cat "${goseq}" | wc -l)

	# If file is not empty
  if (( "${linecount}" > 1 ))
	then
		output_file="${goseq}.flattened"


		# 1st: Convert comma-delimited gene IDs in column 10 to tab-delimited
		# Also, set output (OFS) to be tab-delimited
		# 2nd: Convert spaces to underscores and keep output as tab-delimited
		# 3rd: Sort on Trinity IDs (column 10) and keep only uniques
		awk 'BEGIN{FS="\t";OFS="\t"} {gsub(/, /, "\t", $10); print}' "${goseq}" \
		| awk 'BEGIN{F="\t";OFS="\t"} NR==1; NR > 1 {gsub(/ /, "_", $0); print}' \
		> "${tmp_file}"

		# Identify the first line number which contains a gene_id
		begin_goterms=$(grep --line-number "TRINITY" "${tmp_file}" \
		| awk '{for (i=1;i<=NF;i++) if($i ~/TRINITY/) print i}' \
		| sort --general-numeric-sort --unique | head -n1)

		# "Unfolds" gene_ids to a single gene_id per row
		while read -r line
		do
			# Capture the length of the longest row
			max_field=$(echo "$line" | awk -F "\t" '{print NF}')

			# Retain the first 8 fields (i.e. categories)
			fixed_fields=$(echo "$line" | cut -f1-8)

			# Since not all the lines contain the same number of fields (e.g. may not have GO terms),
			# evaluate the number of fields in each line to determine how to handle current line.

			# If the value in max_field is less than the field number where the GO terms begin,
			# then just print the current line (%s) followed by a newline (\n).
			if (( "$max_field" < "$begin_goterms" ))
			then
				printf "%s\n" "$line"
			else goterms=$(echo "$line" | cut -f"$begin_goterms"-"$max_field")

		  # Assign values in the variable "goterms" to a new indexed array (called "array"),
		  # with tab delimiter (IFS=$'\t')
		  IFS=$'\t' read -r -a array <<<"$goterms"

		  # Iterate through each element of the array.
		  # Print the first n fields (i.e. the fields stored in "fixed_fields") followed by a tab (%s\t).
		  # Print the current element in the array (i.e. the current GO term) followed by a new line (%s\n).
		  for element in "${!array[@]}"
		  do
			  printf "%s\t%s\n" "$fixed_fields" "${array[$element]}"
		  done
		  fi
		done < "${tmp_file}" > "${output_file}"
	fi

  # Cleanup
  rm "${tmp_file}"

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