#!/bin/env bash

# Differential gene expression analysis

# Exit script if any command fails
set -e

## Set input file locations
trimmed_reads_dir=/mnt/data/coral_RNAseq_2017/porites/20180311_fastqc_trimming/trimmed
salmon_out_dir=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_salmon_abundance_FvM_k5
symbio_transcriptome_dir=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts
symbio_transcriptome=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta
symbio_fasta_index=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta.fai
samples=/home/sam/gitrepos/coral_rnaseq_2017/scripts/porites_male_vs_female_k5_trinity_sample_list.txt
gene_map=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta.gene_trans_map

salmon_stdout=20190426_salmon.out
salmon_stderr=20190426_salmon.err

#programs
trinity_abundance=/home/shared/Trinityrnaseq-v2.6.6/util/align_and_estimate_abundance.pl
trinity_matrix=/home/shared/Trinityrnaseq-v2.6.6/util/abundance_estimates_to_matrix.pl
trinity_DE=/home/shared/Trinityrnaseq-v2.6.6/Analysis/DifferentialExpression/run_DE_analysis.pl
diff_expr=/home/shared/Trinityrnaseq-v2.6.6/Analysis/DifferentialExpression/analyze_diff_expr.pl

# Run differential expression on edgeR output matrix
# Set fold difference to 2-fold (ie. -C 1 = 2^1)
# P value <= 0.05
${diff_expr} \
--matrix salmon.isoform.TMM.EXPR.matrix \
--samples ${samples} \
-C 1 \
-P 0.05

# Email me when job is complete
sed '/^Subject:/ s/ / porites_salmon JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
