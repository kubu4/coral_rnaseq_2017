#!/bin/env bash

# Pull out coral transcripts based on BLAST results

## Set input file locations
transcriptome=/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta
transcripts_list=/media/sam/4TB_toshiba/montipora/20190129_blastx_ncbi_sp-v5_montipora/20190129_blastx_sp_montipora_cnidarian.list

## Set output file locations/names
out_dir=/media/sam/4TB_toshiba/montipora/20190129_sp_coral_transcripts
coral_transcriptome=${out_dir}/Trinity.sp.coral.fasta

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
