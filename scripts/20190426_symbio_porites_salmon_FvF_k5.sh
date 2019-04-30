#!/bin/env bash

# Differential gene expression analysis

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

cd ${trimmed_reads_dir}

time ${trinity_abundance} \
--output_dir ${salmon_out_dir} \
--transcripts ${symbio_transcriptome} \
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

# Differential expression analysis
cd ${symbio_transcriptome_dir}
${trinity_DE} \
--matrix ${salmon_out_dir}/salmon.isoform.counts.matrix \
--method edgeR \
--samples_file ${samples}

mv edgeR* ${salmon_out_dir}

# Email me when job is complete
sed '/^Subject:/ s/ / porites_salmon JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
