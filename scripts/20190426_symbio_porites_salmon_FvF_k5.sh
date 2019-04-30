#!/bin/env bash

# Differential gene expression analysis

## Set input file locations
trimmed_reads_dir=/mnt/data/coral_RNAseq_2017/porites/20180311_fastqc_trimming/trimmed
salmon_out_dir=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_salmon_abundance_FvM_k5
sybmio_transcriptome=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta
symbio_fasta_index=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta.fai
samples=/home/sam/gitrepos/coral_rnaseq_2017/scripts/porites_male_vs_female_k5_trinity_sample_list.txt
gene_map=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta.gene_trans_map

salmon_stdout=20190426_salmon.out
salmon_stderr=20190426_salmon.err

cd ${trimmed_reads_dir}

time  /home/shared/Trinityrnaseq-v2.6.6/util/align_and_estimate_abundance.pl \
--output_dir ${salmon_out_dir} \
--transcripts ${coral_transcriptome} \
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

# Email me when job is complete
sed '/^Subject:/ s/ / porites_salmon JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
