#!/bin/env bash

# Script to run InParanoid using two ingroups and an outgroup
# Script must be executed in the "inparanoid_4.1" directory.
# User must set paths to input files and blastall and formatdb program paths below.

# Exit script if a command fails
set -e

# Paths to input files
protein_fasta="/media/sam/4TB_toshiba/porites/20180429_transdecoder/Trinity.fasta.transdecoder.pep.complete-ORFS-only.fasta"
ingroup_fasta="/mnt/data/porites_astreoides_matz/pastreoides_2014/pastreoides_may2014/past_PRO.fas"
outgroup_fasta="/mnt/data/symbiodinium_minutum_prot/symbB.v1.2.augustus.prot.fa"

# Use sed to modify InParanoid config file
# Uses the "%" as the substitute delimiter to allow usage of "/" in paths
## Set blastall location
sed -i '/^$blastall = "blastall"/ s%"blastall"%"/home/shared/blast-2.2.17/bin/blastall -a23"%' inparanoid.pl

## Set formatdb location
sed -i '/^$formatdb = "formatdb"/ s%"formatdb"%"/home/shared/blast-2.2.17/bin/formatdb"%' inparanoid.pl

## Set InParanoid to use an out group (change from 0 to 1)
sed -i '/^$use_outgroup = 0/ s%0%1%' inparanoid.pl

# Copy files to working directory
rsync -a "${protein_fasta}" .
rsync -a "${ingroup_fasta}" .
rsync -a "${outgroup_fasta}" .

# Run inparanoid
## The two ingroup files have to be listed first
## The outgrop file has be the last input file listed
perl inparanoid.pl \
"${protein_fasta}" \
"${ingroup_fasta}" \
"${outgroup_fasta}" \
1>stdout.txt \
2>stderr.txt

# Send email when job finishes
sed '/^Subject:/ s/ / porites inparanoid JOB COMPLETE/' ~/.default-subject.mail | msmtp "$EMAIL"
