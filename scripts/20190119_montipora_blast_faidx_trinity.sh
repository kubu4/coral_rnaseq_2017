#!/bin/env bash

# Pull out coral transcripts based on BLAST results

## Set input file locations
transcriptome=/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta
transcripts_list=/media/sam/4TB_toshiba/montipora/20190105_blastx_ncbi_nr-v5_montipora/20190105_blastx_nr_montipora.list
## Set output file locations/names
out_dir=/media/sam/4TB_toshiba/montipora
out_fasta=${out_dir}/Trinity.coral.fasta
out_fai=${out_dir}/Trinity.coral.fasta.fai

## Set program locations
faidx="/home/shared/samtools-1.9/samtools faidx"

cd ${out_dir}

# Pull out coral only seqs from Trinity transcriptome
while read contig; do
  ${faidx} \
  ${transcriptome} \
  ${contig} \
  >> ${out_fasta}
done < ${transcripts_list}

## Create index for new fasta
${faidx} ${out_fasta}
