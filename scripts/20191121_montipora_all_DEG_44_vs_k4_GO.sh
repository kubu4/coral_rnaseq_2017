#!/bin/env bash

# Differential gene expression analysis

# Exit script if any command fails
set -e

## Set input file locations
trimmed_reads_dir="/mnt/data/coral_RNAseq_2017/montipora/20180311_fastqc_trimming/trimmed"
salmon_out_dir="/media/sam/4TB_toshiba/montipora/20191121_montipora_all_DEG_44_vs_k4_GO"
transcriptome_dir="/media/sam/4TB_toshiba/montipora/20180416_trinity"
transcriptome="${transcriptome_dir}/Trinity.fasta"
fasta_index="${transcriptome_dir}/Trinity.fasta.fai"
fasta_seq_lengths="${transcriptome_dir}/Trinity.fasta.seq_lens"
samples="/home/sam/gitrepos/coral_rnaseq_2017/scripts/montipora_44_vs_k4_trinity_sample_list.txt"

gene_map="${transcriptome_dir}/Trinity.fasta.gene_trans_map"
salmon_gene_matrix="${salmon_out_dir}/salmon.gene.TMM.EXPR.matrix"
salmon_iso_matrix="${salmon_out_dir}/salmon.isoform.TMM.EXPR.matrix"
go_annotations="/media/sam/4TB_toshiba/montipora/20190530_trinotate_montipora_all/go_annotations.txt"


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
--aln_method bowtie2 \
--gene_trans_map "${gene_map}" \
--prep_reference \
--thread_count 23 \
1> ${salmon_out_dir}/${salmon_stdout} \
2> ${salmon_out_dir}/${salmon_stderr}
# Move output folders
mv ${trimmed_reads_dir}/[nb][b_]* \
${salmon_out_dir}
cd ${salmon_out_dir}
# Convert abundance estimates to matrix
${trinity_matrix} \
--est_method salmon \
--gene_trans_map ${gene_map} \
--out_prefix salmon \
--name_sample_by_basedir \
bleached_k4_01/quant.sf \
bleached_44_01/quant.sf \
bleached_k4_02/quant.sf \
bleached_44_02/quant.sf \
bleached_44_03/quant.sf \
bleached_k4_03/quant.sf \
b_44_01/quant.sf \
b_44_02/quant.sf \
b_44_03/quant.sf \
nb_44_04/quant.sf \
nb_44_05/quant.sf \
nb_44_06/quant.sf \
b_k4_01/quant.sf \
b_k4_02/quant.sf \
b_k4_03/quant.sf \
nb_k4_04/quant.sf \
nb_k4_05/quant.sf \
nb_k4_06/quant.sf \
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
