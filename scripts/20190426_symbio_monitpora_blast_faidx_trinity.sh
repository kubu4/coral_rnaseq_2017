#!/bin/env bash

# Pull out coral transcripts based on BLAST results

## Set input file locations
blastx_out=/media/sam/4TB_toshiba/montipora/20190425_blastx_ncbi_sp-v5_symbio_montipora/20190425_blastx_ncbi_sp-v5_symbio_montipora.tab
transcriptome=/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta

## Set output file locations/names
out_dir=/media/sam/4TB_toshiba/montipora/20190426_symbio_montipora_transcripts
transcripts_list=/media/sam/4TB_toshiba/montipora/20190426_symbio_montipora_transcripts/20190426_symbio_montipora_transcripts.list
sybmio_transcriptome=${out_dir}/Trinity.sp.symbio_montipora.fasta

## Set program locations
faidx="/home/shared/samtools-1.9/samtools faidx"

cd ${out_dir}

# Create transcripts list from blastx output
awk -F"." '{print $1}' ${blastx_out} \
| sort -u \
> ${transcripts_list}

# Pull out coral only seqs from Trinity transcriptome
while read contig; do
  ${faidx} \
  ${transcriptome} \
  ${contig} \
  >> ${symbio_transcriptome}
done < ${transcripts_list}

## Create index for new fasta
${faidx} ${coral_transcriptome}

# Email me when job is complete
sed '/^Subject:/ s/ / porites_montipora JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
