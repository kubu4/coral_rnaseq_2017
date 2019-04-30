#!/bin/env bash

# Differential gene expression analysis

## Set input file locations
salmon_out_dir=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_salmon_abundance_FvM_k5
sybmio_transcriptome=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta
symbio_fasta_index=/media/sam/4TB_toshiba/porites/20190426_symbio_porites_transcripts/Trinity.sp.symbio_porites.fasta.fai
samples=/home/sam/gitrepos/coral_rnaseq_2017/scripts/porites_male_vs_female_k5_trinity_sample_list.txt
gene_map=/media/sam/4TB_toshiba/porites/

salmon_stdout=20190426_salmon.out
salmon_stderr=20190426_salmon.err



# Email me when job is complete
sed '/^Subject:/ s/ / porites_salmon JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
