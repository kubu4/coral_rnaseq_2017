#!/bin/env bash

# Script to pull subset of Transdecoder complete ORFs proteins
# based on InParanoid ortholog comparison between corals and symbiodinium.

# Exit script if a command fails
set -e
# Save current directory as working directory.
wd="$(pwd)"

# Input/output files
blastp_out_dir=/media/sam/4TB_toshiba/porites/20190520_montipora_blastp_inparanoid_sp-v5
orf_fasta=/media/sam/4TB_toshiba/porites/20180803_cd-hit/20180803_cd-hit_porites.txt
orf_fasta_index=/media/sam/4TB_toshiba/porites/20180803_cd-hit/20180803_cd-hit_porites.txt.fai
blastp_out_file=20190520_porites_blastp_inparanoid_sp-v5.tab

inparanoid_coral_table="/media/sam/4TB_toshiba/porites/20181206_inparanoid/inparanoid_4.1/table.20180803_cd-hit_porites.txt-past_PRO.fas"

# Output files
coral_list="${wd}/inparanoid-list.txt"
coral_fasta="${wd}/inparanoid_coral.fasta"

# Programs variables
blastp=/home/shared/ncbi-blast-2.8.1+/bin/blastp
blastdb_dir=/mnt/data/ncbi_swissprot_v5_db
sp_db=swissprot_v5
samtools="/home/shared/samtools-1.9/samtools"

# Copy FastA and index file
rsync -a "${orf_fasta}" .
rsync -a "${orf_fasta_index}" .

# Create FastA index file
"${samtools}" faidx "${orf_fasta}"

# Pull out Trinity contig names
# based on InParanoid inparalogs
awk 'NR>1 { print $3 }' "${inparanoid_coral_table}" \
> "${coral_list}"


# Use faidx and FastA index
# to create new FastA subset.
while read -r contig
do
  "${samtools}" faidx "${orf_fasta}" "${contig}" \
  >> "${coral_fasta}"
done < "${coral_list}"

# Index new FastA
${samtools} faidx "${coral_fasta}"

# Run blastp
cd ${blastdb_dir}

export BLASTDB=${blastdb_dir}

time \
${blastp} \
-query ${orf_fasta} \
-db ${blastdb_dir}/${sp_db} \
-evalue 1E-04 \
-outfmt "6 std staxids" \
-max_hsps 1 \
-max_target_seqs 1 \
-num_threads 23 \
-out ${blastp_out_dir}/${blastp_out_file} \
1> blastp_stdout.txt \
2> blastp_stderr.txt

sed '/^Subject:/ s/ / porites_blastp JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
