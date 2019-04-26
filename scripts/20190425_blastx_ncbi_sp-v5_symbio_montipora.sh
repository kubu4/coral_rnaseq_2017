#!/bin/env bash

# Input/output files
blastx_out_dir=/media/sam/4TB_toshiba/montipora/20190425_blastx_ncbi_sp-v5_symbio_montipora
taxid_list=/media/sam/4TB_toshiba/montipora/20190425_blastx_ncbi_sp-v5_symbio_montipora/dinoflagellate.taxids
orf_fasta=/media/sam/4TB_toshiba/montipora/20180429_transdecoder/Trinity.fasta.transdecoder.cds.complete-ORFS-only.fasta
blastx_out_file=20190425_blastx_ncbi_sp-v5_symbio_montipora.tab
taxid=

# Programs variables
get_taxids=/home/shared/ncbi-blast-2.8.1+/bin/get_species_taxids.sh
blastx=/home/shared/ncbi-blast-2.8.1+/bin/blastx
blastdb_dir=/mnt/data/ncbi_swissprot_v5_db
sp_db=swissprot_v5



#Get NCBI taxonomic ID for dinoflagellates
taxid=$("$get_taxids" -n dinoflagellates | grep "Taxid:" | awk '{print $2}')

# Generate list of all NCBI taxonomic IDs belonging to dinoflagellates
${get_taxids} -t ${taxid} \
> ${taxid_list}


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
--max_hsps 1 \
-num_threads 23 \
-out ${blastx_out_dir}/${blastx_out_file} \
1> blastx_stdout.txt \
2> blastx_stderr.txt

sed '/^Subject:/ s/ / montipora_symbio_blastx JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
