#!/bin/env bash

# Differential gene expression analysis

# Exit script if any command fails
set -e

## Set input file locations
trimmed_reads_dir="/mnt/data/coral_RNAseq_2017/montipora/20180415_trimmed"
salmon_out_dir="/media/sam/4TB_toshiba/montipora/20190603_all_salmon_DEG_b_vs_nb"
transcriptome_dir="/media/sam/4TB_toshiba/montipora/20180416_trinity"
transcriptome="${transcriptome_dir}/Trinity.fasta"
fasta_index="${transcriptome_dir}/Trinity.fasta.fai"
fasta_seq_lengths="${transcriptome_dir}/Trinity.fasta.seq_lens"
samples="/home/sam/gitrepos/coral_rnaseq_2017/scripts/montipora_b_vs_nb_trinity_sample_list.txt"

gene_map="${transcriptome_dir}/Trinity.fasta.gene_trans_map"
salmon_matrix="${salmon_out_dir}/salmon.isoform.TMM.EXPR.matrix"
go_annotations="/media/sam/4TB_toshiba/montipora/20190530_trinotate_montipora_all/go_annotations.txt"


salmon_stdout="stdout.txt"
salmon_stderr="stderr.txt"

edgeR_dir=""

#programs
trinity_abundance=/home/shared/Trinityrnaseq-v2.6.6/util/align_and_estimate_abundance.pl
trinity_matrix=/home/shared/Trinityrnaseq-v2.6.6/util/abundance_estimates_to_matrix.pl
trinity_DE=/home/shared/Trinityrnaseq-v2.6.6/Analysis/DifferentialExpression/run_DE_analysis.pl
diff_expr=/home/shared/Trinityrnaseq-v2.6.6/Analysis/DifferentialExpression/analyze_diff_expr.pl
trinity_tpm_length=/home/shared/Trinityrnaseq-v2.6.6/util/misc/TPM_weighted_gene_length.py


cd ${trimmed_reads_dir}

time ${trinity_abundance} \
--output_dir ${salmon_out_dir} \
--transcripts ${transcriptome} \
--seqType fq \
--samples_file ${samples} \
--SS_lib_type RF \
--est_method salmon \
--aln_method bowtie2 \
--trinity_mode \
--prep_reference \
--thread_count 23 \
1> ${salmon_out_dir}/${salmon_stdout} \
2> ${salmon_out_dir}/${salmon_stderr}

# Move output folders
mv ${trimmed_reads_dir}/[mf][ae][lm]* \
${salmon_out_dir}

cd ${salmon_out_dir}

# Convert abundance estimates to matrix
${trinity_matrix} \
--est_method salmon \
--gene_trans_map ${gene_map} \
--out_prefix salmon \
--name_sample_by_basedir \
male_bleached_K5_03/quant.sf \
female_bleached_K5_06/quant.sf \
female_bleached_K5_04/quant.sf \
male_bleached_K5_02/quant.sf \
male_bleached_K5_01/quant.sf \
female_bleached_K5_05/quant.sf

# Generate weighted gene lengths
"${trinity_tpm_length}" \
--gene_trans_map "${gene_trans_map}" \
--trans_lengths "${fasta_seq_lengths}" \
 --TPM_matrix "${salmon_matrix}" \
 > Trinity.gene_lengths.txt

# Differential expression analysis
cd ${transcriptome_dir}
${trinity_DE} \
--matrix ${salmon_out_dir}/salmon.isoform.counts.matrix \
--method edgeR \
--samples_file ${samples}

mv edgeR* ${salmon_out_dir}

# Run differential expression on edgeR output matrix
# Set fold difference to 2-fold (ie. -C 1 = 2^1)
# P value <= 0.05
# Has to run from edgeR output directory

# Pulls edgeR directory name and removes leading ./ in find output
cd ${salmon_out_dir}
edgeR_dir=$(find . -type d -name "edgeR*" | sed 's%./%%')
cd ${edgeR_dir}
${diff_expr} \
--matrix ${salmon_out_dir}/salmon.isoform.TMM.EXPR.matrix \
--samples ${samples} \
--examine_GO_enrichment \
--GO_annots "${go_annotations}" \
--gene_lengths ${salmon_out_dir}/Trinity.gene_lengths.txt \
-C 1 \
-P 0.05

# Email me when job is complete
sed '/^Subject:/ s/ / JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"