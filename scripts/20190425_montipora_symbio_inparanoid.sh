#!/bin/env bash

# Script to pull subset of Trinity assembly
# based on InParanoid ortholog comparison between corals and symbiodinium.


# Programs
samtools="home/shared/samtools-1.9/samtools"

# Input files
inparanoid_coral_rejects="/media/sam/4TB_toshiba/montipora/20181204_inparanoid/inparanoid_4.1/rejected_sequences.symbB.v1.2.augustus.prot.fa"
trinity_fasta="/media/sam/4TB_toshiba/montipora/20180416_trinity.fasta"
trinity_fai="/media/sam/4TB_toshiba/montipora/20180416_trinity.fasta.fai"

# Output files
symbio_trinity_list="symbio-list.txt"
symbio_fasta="symbio-monitpora.fasta"
symbio_fai="symbio-monitpora.fasta"

# Pull out Trinity contig names
# based on InParanoid rejects list
grep "Ortholog pair "${inparanoid_coral_rejects} \
| tr " " "." \
| tr "(" "." \
| awk -F"." '{ print $5 }' \
> ${symbio_trinity_list}

# Pull out FastA index subset based on InParanoid
# rejects list.
grep --file=${symbio_trinity_list} ${trinity_fai} \
> ${symbio_fai}

# Use faidx and new symbiodinium FastA index
# to create new FastA subset.
while read contig
do
  ${samtools} faidx ${contig} \
  >> ${symbio_fasta}
done < ${symbio_fai}
