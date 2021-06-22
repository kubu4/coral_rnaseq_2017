#!/usr/bin/bash

# Differential gene expression analysis

# Exit script if any command fails
set -e

## Set input file locations
trimmed_reads_dir="/mnt/data/coral_RNAseq_2017/porites/20180311_fastqc_trimming/trimmed"
salmon_out_dir="/media/sam/4TB_toshiba/porites/20210622_porites_cnidaria_DEG_bleached_vs_non-bleached_all_GO"
transcriptome_dir="/media/sam/4TB_toshiba/porites/20210613_pcom_diamond_blastx_transcriptome"
transcriptome="${transcriptome_dir}/Cnidaria_MEGAN-extractions.fasta"
fasta_index="${transcriptome_dir}/Cnidaria_MEGAN-extractions.fasta.fai"
fasta_seq_lengths="${transcriptome_dir}/Cnidaria_MEGAN-extractions.fasta.seq_lens"
samples="/home/sam/gitrepos/coral_rnaseq_2017/scripts/porites_b_vs_nb_trinity_sample_list.txt"

# Create directory/sample list for ${trinity_matrix} command
trin_matrix_list=$(awk '{printf "%s%s", $2, "/quant.sf " }' "${samples}")

gene_map="${transcriptome_dir}/Cnidaria_MEGAN-extractions.fasta.gene_trans_map"
salmon_gene_matrix="${salmon_out_dir}/salmon.gene.TMM.EXPR.matrix"
salmon_iso_matrix="${salmon_out_dir}/salmon.isoform.TMM.EXPR.matrix"
go_annotations="/media/sam/4TB_toshiba/porites/20190530_trinotate_porites_all/go_annotations.txt"


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

#programs
trinity_abundance=/home/shared/Trinityrnaseq-v2.8.5/util/align_and_estimate_abundance.pl
trinity_matrix=/home/shared/Trinityrnaseq-v2.8.5/util/abundance_estimates_to_matrix.pl
trinity_DE=/home/shared/Trinityrnaseq-v2.8.5/Analysis/DifferentialExpression/run_DE_analysis.pl
diff_expr=/home/shared/Trinityrnaseq-v2.8.5/Analysis/DifferentialExpression/analyze_diff_expr.pl
trinity_tpm_length=/home/shared/Trinityrnaseq-v2.8.5/util/misc/TPM_weighted_gene_length.py


cd ${trimmed_reads_dir}
time ${trinity_abundance} \
--output_dir ${salmon_out_dir} \
--transcripts ${transcriptome} \
--seqType fq \
--samples_file ${samples} \
--SS_lib_type RF \
--est_method salmon \
--gene_trans_map "${gene_map}" \
--thread_count 23 \
1> ${salmon_out_dir}/${salmon_stdout} \
2> ${salmon_out_dir}/${salmon_stderr}
# Move output folders
mv ${trimmed_reads_dir}/[fm]* \
${salmon_out_dir}
cd ${salmon_out_dir}
# Convert abundance estimates to matrix
${trinity_matrix} \
--est_method salmon \
--gene_trans_map ${gene_map} \
--out_prefix salmon \
--name_sample_by_basedir ${trin_matrix_list} \
1> ${matrix_stdout} \
2> ${matrix_stderr}

# Generate weighted gene lengths
"${trinity_tpm_length}" \
--gene_trans_map "${gene_map}" \
--trans_lengths "${fasta_seq_lengths}" \
--TPM_matrix "${salmon_iso_matrix}" \
> Trinity.gene_lengths.txt \
2> ${tpm_length_stderr}

# Differential expression analysis
cd ${transcriptome_dir}
${trinity_DE} \
--matrix ${salmon_out_dir}/salmon.gene.counts.matrix \
--method edgeR \
--samples_file ${samples} \
1> ${trinity_DE_stdout} \
2> ${trinity_DE_stderr}

mv edgeR* ${salmon_out_dir}


# Run differential expression on edgeR output matrix
# Set fold difference to 2-fold (ie. -C 1 = 2^1)
# P value <= 0.05
# Has to run from edgeR output directory

# Pulls edgeR directory name and removes leading ./ in find output
cd ${salmon_out_dir}
edgeR_dir=$(find . -type d -name "edgeR*" | sed 's%./%%')
cd "${edgeR_dir}"
mv "${transcriptome_dir}/${trinity_DE_stdout}" .
mv "${transcriptome_dir}/${trinity_DE_stderr}" .
${diff_expr} \
--matrix "${salmon_gene_matrix}" \
--samples ${samples} \
--examine_GO_enrichment \
--GO_annots "${go_annotations}" \
--include_GOplot \
--gene_lengths ${salmon_out_dir}/Trinity.gene_lengths.txt \
-C 1 \
-P 0.05 \
1> ${diff_expr_stdout} \
2> ${diff_expr_stderr}

# Email me when job is complete
sed '/^Subject:/ s/ / JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
