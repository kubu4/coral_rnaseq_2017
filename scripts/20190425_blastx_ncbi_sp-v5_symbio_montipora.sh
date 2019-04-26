#!/bin/env bash

# Input/output files
blastx_out_dir=/media/sam/4TB_toshiba/montipora/20190425_blastx_ncbi_sp-v5_symbio_montipora
taxid_list=/media/sam/4TB_toshiba/montipora/20190425_blastx_ncbi_sp-v5_symbio_montipora/dinoflagellate.taxids
orf_fasta=/media/sam/4TB_toshiba/montipora/20180429_transdecoder/Trinity.fasta.transdecoder.cds.complete-ORFS-only.fasta

# Programs variables
get_taxids=/home/shared/ncbi-blast-2.8.1+/bin/get_species_taxids.sh
blastx=/home/shared/ncbi-blast-2.8.1+/bin/blastx
blastdb_dir=/mnt/data/ncbi_swissprot_v5_db
sp_db=swissprot_v5
blastx_out_file=20190425_blastx_ncbi_sp-v5_symbio_montipora.tab
