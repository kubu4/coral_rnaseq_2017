#!/bin/env bash

# Pull out coral transcripts based on BLAST results

## Set input file locations
transcriptome=/media/sam/4TB_toshiba/porites/20180419_trinity/Trinity.fasta
transcripts_list=/media/sam/4TB_toshiba/porites/20190115_blastx_ncbi_nr-v5_porites/20190115_blastx_nr_porites.list

## Set output file locations/names
out_dir=/media/sam/4TB_toshiba/porites/coral_transcripts/
coral_transcriptome=${out_dir}/Trinity.coral.fasta

## Set program locations
faidx="/home/shared/samtools-1.9/samtools faidx"

cd ${out_dir}

# Pull out coral only seqs from Trinity transcriptome
while read contig; do
  ${faidx} \
  ${transcriptome} \
  ${contig} \
  >> ${coral_transcriptome}
done < ${transcripts_list}

## Create index for new fasta
${faidx} ${coral_transcriptome}

# Email me when job is complete
sed '/^Subject:/ s/ / porites_faidx JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
