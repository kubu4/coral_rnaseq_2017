#!/bin/env bash

# BUSCO analysis for all Montipora transcriptome seqs

# Exit script if any command fails
set -e

## Input files and settings
base_name=montipora_all
busco_db=/home/shared/busco-v3/metazoa_odb9
transcriptome_fasta=/media/sam/4TB_toshiba/montipora/20180416_trinity/Trinity.fasta
augustus_species=fly
threads=23

## Save working directory
wd=$(pwd)

## Set program paths
augustus_bin=/home/shared/Augustus-3.3.2/bin
augustus_scripts=/home/shared/Augustus-3.3.2/scripts
blast_dir=/home/shared/ncbi-blast-2.8.1+/bin/
busco=/home/shared/busco-v3/scripts/run_BUSCO.py
hmm_dir=/home/shared/hmmer-3.2.1/src/

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

# Make Augustus directory if it doesn't exist
if [ ! -d "${augustus_dir}" ]; then
  mkdir --parents "${augustus_dir}"
fi

# Copy Augustus config directory
cp --preserve --recursive ${augustus_orig_config_dir} "${augustus_dir}"

# Run BUSCO/Augustus training
${busco} \
--in ${transcriptome_fasta} \
--out ${base_name} \
--lineage_path ${busco_db} \
--mode transcriptome \
--cpu "${threads}" \
--long \
--species ${augustus_species} \
--tarzip \
--augustus_parameters='--progress=true'

# Email me when job is complete
sed '/^Subject:/ s/ / JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
