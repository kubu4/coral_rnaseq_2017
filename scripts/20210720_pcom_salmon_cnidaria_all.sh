#!/usr/bin/bash

# Differential gene expression analysis

# Exit script if any command fails
set -e

## Set input file locations
trimmed_reads_dir="/mnt/data/coral_RNAseq_2017/porites/20180311_fastqc_trimming/trimmed"
salmon_out_dir="/media/sam/4TB_toshiba/porites/20210720_pcom_salmon_cnidaria_all"
transcriptome_dir="/media/sam/4TB_toshiba/porites/20210720_pcom_trinity_cnidaria_RNAseq"
transcriptome="${transcriptome_dir}/pcom_cnidaria_transcriptome_v1.0.fasta"
fasta_index="${transcriptome_dir}/pcom_cnidaria_transcriptome_v1.0.fasta.fai"
fasta_seq_lengths="${transcriptome_dir}/pcom_cnidaria_transcriptome_v1.0.fasta.seq_lens"
samples="/home/sam/gitrepos/coral_rnaseq_2017/scripts/porites_b_vs_nb_trinity_sample_list.txt"

# Create directory/sample list for ${trinity_matrix} command
trin_matrix_list=$(awk '{printf "%s%s", $2, "/quant.sf " }' "${samples}")

gene_map="${transcriptome_dir}/pcom_cnidaria_transcriptome_v1.0.fasta.gene_trans_map"
salmon_gene_matrix="${salmon_out_dir}/salmon.gene.TMM.EXPR.matrix"
salmon_iso_matrix="${salmon_out_dir}/salmon.isoform.TMM.EXPR.matrix"


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
--prep_reference \
1> ${salmon_out_dir}/${salmon_stdout} \
2> ${salmon_out_dir}/${salmon_stderr}
# Move output folders
mv ${trimmed_reads_dir}/[bn]* \
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


# Email me when job is complete
sed '/^Subject:/ s/ / JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
