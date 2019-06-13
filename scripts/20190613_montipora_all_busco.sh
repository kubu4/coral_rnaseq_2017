#!/bin/env bash

# BUSCO analysis for all Montipora transcriptome seqs

# Exit script if any command fails
set -e

## Input files and settings
base_name=montipora_all
busco_db=/home/shared/busco_v3/metazoa_odb9
transcriptome_fasta=/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta
transcriptome_index=${genome_fasta}.fai
augustus_species=fly
threads=28

## Save working directory
wd=$(pwd)

## Set program paths
augustus_bin=/home/shared/Augustus-3.3.2/bin
augustus_scripts=/home/shared/Augustus-3.3.2/scripts
bedtools=/home/shared/bedtools-2.27.1/bin/bedtools
blast_dir=/home/shared/ncbi-blast-2.8.1+/bin/
busco=/home/shared/busco-v3/scripts/run_BUSCO.py
hmm_dir=/home/shared/hmmer-3.2.1/src/
samtools=/home/shared/samtools-1.9/samtools

## Augustus configs
augustus_dir=${wd}/augustus
augustus_config_dir=${augustus_dir}/config
augustus_orig_config_dir=/home/shared/Augustus-3.3.2/config

## BUSCO configs
busco_config_default=/home/shared/busco-v3/config/config.ini.default
busco_config_ini=${wd}/config.ini

# Export BUSCO config file location
export BUSCO_CONFIG_FILE="${busco_config_ini}"

# Export Augustus variable
export PATH="${augustus_bin}:$PATH"
export PATH="${augustus_scripts}:$PATH"
export AUGUSTUS_CONFIG_PATH="${augustus_config_dir}"


# Copy BUSCO config file
cp ${busco_config_default} ${busco_config_ini}

# Make Augustus directory if it doesn't exist
if [ ! -d ${augustus_dir} ]; then
  mkdir --parents ${augustus_dir}
fi

# Copy Augustus config directory
cp --preserve -r ${augustus_orig_config_dir} ${augustus_dir}

# Edit BUSCO config file
## Set paths to various programs
### The use of the % symbol sets the delimiter sed uses for arguments.
### Normally, the delimiter that most examples use is a slash "/".
### But, we need to expand the variables into a full path with slashes, which screws up sed.
### Thus, the use of % symbol instead (it could be any character that is NOT present in the expanded variable; doesn't have to be "%").
sed -i "/^;cpu/ s/1/28/" "${busco_config_ini}"
sed -i "/^tblastn_path/ s%tblastn_path = /usr/bin/%path = ${blast_dir}%" "${busco_config_ini}"
sed -i "/^makeblastdb_path/ s%makeblastdb_path = /usr/bin/%path = ${blast_dir}%" "${busco_config_ini}"
sed -i "/^augustus_path/ s%augustus_path = /home/osboxes/BUSCOVM/augustus/augustus-3.2.2/bin/%path = ${augustus_bin}%" "${busco_config_ini}"
sed -i "/^etraining_path/ s%etraining_path = /home/osboxes/BUSCOVM/augustus/augustus-3.2.2/bin/%path = ${augustus_bin}%" "${busco_config_ini}"
sed -i "/^gff2gbSmallDNA_path/ s%gff2gbSmallDNA_path = /home/osboxes/BUSCOVM/augustus/augustus-3.2.2/scripts/%path = ${augustus_scripts}%" "${busco_config_ini}"
sed -i "/^new_species_path/ s%new_species_path = /home/osboxes/BUSCOVM/augustus/augustus-3.2.2/scripts/%path = ${augustus_scripts}%" "${busco_config_ini}"
sed -i "/^optimize_augustus_path/ s%optimize_augustus_path = /home/osboxes/BUSCOVM/augustus/augustus-3.2.2/scripts/%path = ${augustus_scripts}%" "${busco_config_ini}"
sed -i "/^hmmsearch_path/ s%hmmsearch_path = /home/osboxes/BUSCOVM/hmmer/hmmer-3.1b2-linux-intel-ia32/binaries/%path = ${hmm_dir}%" "${busco_config_ini}"


# Run BUSCO/Augustus training
${busco} \
--in ${genome_fasta} \
--out ${base_name} \
--lineage_path ${busco_db} \
--mode genome \
--cpu "${threads}" \
--long \
--species ${augustus_species} \
--tarzip \
--augustus_parameters='--progress=true'
