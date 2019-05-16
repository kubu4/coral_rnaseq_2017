#!/bin/env bash



# Exit script if a command fails
set -e


# Input/output files
blastx_out_dir=/media/sam/4TB_toshiba/montipora/20190515_montipora_blastx_inparanoid_sp-v5
orf_fasta=/media/sam/4TB_toshiba/porites/20180429_transdecoder/Trinity.fasta.transdecoder.cds.complete-ORFS-only.fasta
blastx_out_file=20190515_montipora_blastx_inparanoid_sp-v5.tab

# Programs variables
blastx=/home/shared/ncbi-blast-2.8.1+/bin/blastx
blastdb_dir=/mnt/data/ncbi_swissprot_v5_db
sp_db=swissprot_v5

#!/bin/env bash

# Script to pull subset of Trinity assembly
# based on InParanoid ortholog comparison between corals and symbiodinium.


# Programs
samtools="/home/shared/samtools-1.9/samtools"

# Input files
inparanoid_coral="/media/sam/4TB_toshiba/montipora/20181204_inparanoid/inparanoid_4.1/table.20180803_cd-hit_montipora.txt-maeq_coral_PRO.fas"
trinity_fasta="/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta"
trinity_fai="/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta.fai"

# Output files
symbio_trinity_list="montipora-inparanoid-list.txt"
symbio_fasta="montipora.fasta"
symbio_fai="montipora.fasta.fai"

# Pull out Trinity contig names
# based on InParanoid inparalogs
awk 'NR>1 { print $3 }' "${inparanoid_coral}" \
> "${coral_trinity_list}"


# Use faidx and new symbiodinium FastA index
# to create new FastA subset.
while read -r contig
do
  ${samtools} faidx "${trinity_fasta}" "${contig}" \
  >> "${symbio_fasta}"
done < "${symbio_trinity_list}"

# Index new FastA
${samtools} faidx "${symbio_fasta}"



# Run blastx
cd ${blastdb_dir}

export BLASTDB=${blastdb_dir}

time \
${blastx} \
-query ${orf_fasta} \
-db ${blastdb_dir}/${sp_db} \
-taxidlist ${taxid_list} \
-evalue 1E-04 \
-outfmt "6 std staxids" \
-max_hsps 1 \
-num_threads 23 \
-out ${blastx_out_dir}/${blastx_out_file} \
1> blastx_stdout.txt \
2> blastx_stderr.txt

sed '/^Subject:/ s/ / porites_symbio_blastx JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
