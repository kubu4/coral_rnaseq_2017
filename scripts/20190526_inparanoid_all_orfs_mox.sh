#!/bin/bash
## Job Name
#SBATCH --job-name=blastx_metagenomics
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=25-00:00:00
## Memory per node
#SBATCH --mem=120G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --workdir=/gscratch/scrubbed/samwhite/outputs/20190526_inparanoid_montipora_all_orfs/inparanoid_4.1

# Exit script if any command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017

# Document programs in PATH (primarily for program version ID)

date >> system_path.log
echo "" >> system_path.log
echo "System PATH for $SLURM_JOB_ID" >> system_path.log
echo "" >> system_path.log
printf "%0.s-" {1..10} >> system_path.log
echo "${PATH}" | tr : \\n >> system_path.log

# Paths to input files for copying
org_protein_fasta="/gscratch/scrubbed/samwhite/data/montipora/Trinity.fasta.transdecoder.pep.complete-ORFS-only.fasta"
org_ingroup_fasta="/gscratch/scrubbed/samwhite/data/montipora/maeq_coral_PRO.fas"
org_outgroup_fasta="/gscratch/scrubbed/samwhite/data/montipora/symbB.v1.2.augustus.prot.fa"


# Input files for InParanoid
protein_fasta="Trinity.fasta.transdecoder.pep.complete-ORFS-only.fasta"
ingroup_fasta="maeq_coral_PRO.fas"
outgroup_fasta="symbB.v1.2.augustus.prot.fa"

# Use sed to modify InParanoid config file
# Uses the "%" as the substitute delimiter to allow usage of "/" in paths
## Set blastall location
sed -i '/^$blastall = "blastall"/ s%"blastall"%"/gscratch/srlab/programs/blast-2.2.17/bin/blastall -a28"%' inparanoid.pl

## Set formatdb location
sed -i '/^$formatdb = "formatdb"/ s%"formatdb"%"/gscratch/srlab/programs/blast-2.2.17/bin/formatdb"%' inparanoid.pl

## Set InParanoid to use an out group (change from 0 to 1)
sed -i '/^$use_outgroup = 0/ s%0%1%' inparanoid.pl

# Copy files to working directory
rsync -a "${org_protein_fasta}" .
rsync -a "${org_ingroup_fasta}" .
rsync -a "${org_outgroup_fasta}" .

# Run inparanoid
## The two ingroup files have to be listed first
## The outgrop file has be the last input file listed
perl inparanoid.pl \
"${protein_fasta}" \
"${ingroup_fasta}" \
"${outgroup_fasta}" \
1>stdout.txt \
2>stderr.txt
