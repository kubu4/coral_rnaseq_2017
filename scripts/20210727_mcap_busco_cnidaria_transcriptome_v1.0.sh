#!/bin/bash
## Job Name
#SBATCH --job-name=20210727_mcap_busco_cnidaria_transcriptome_v1.0
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=00-00:40:00
## Memory per node
#SBATCH --mem=200G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --chdir=/gscratch/scrubbed/samwhite/outputs/20210727_mcap_busco_cnidaria_transcriptome_v1.0

### M.capitata transcriptome assembly completeness assessment using BUSCO.
### This is checking Cnidaria_MEGAN-extractions.fasta from 20210726_mcap_diamond_blastx_transcriptome.

# Load Python Mox module for Python module availability
module load intel-python3_2017

# Load Open MPI module for parallel, multi-node processing
module load icc_19-ompi_3.1.2

# SegFault fix?
export THREADS_DAEMON_MODEL=1


## Input files and settings
busco_db=/gscratch/srlab/sam/data/databases/BUSCO/metazoa_odb9
transcriptome_fasta=/gscratch/srlab/sam/data/M_capitata/transcriptomes/Cnidaria_MEGAN-extractions.fasta
augustus_species=fly
threads=40

## Save working directory
wd=$(pwd)

# Extract FastA filename
fasta_name=${transcriptome_fasta##*/}

## Set program paths
augustus_bin=/gscratch/srlab/programs/Augustus-3.3.2/bin
augustus_scripts=/gscratch/srlab/programs/Augustus-3.3.2/scripts
blast_dir=/gscratch/srlab/programs/ncbi-blast-2.8.1+/bin/
busco=/gscratch/srlab/programs/busco-v3/scripts/run_BUSCO.py
hmm_dir=/gscratch/srlab/programs/hmmer-3.2.1/src/

## Augustus configs
augustus_dir=${wd}/augustus
augustus_config_dir=${augustus_dir}/config
augustus_orig_config_dir=/gscratch/srlab/programs/Augustus-3.3.2/config

## BUSCO configs
busco_config_default=/gscratch/srlab/programs/busco-v3/config/config.ini.default
busco_config_ini=${wd}/config.ini

# Export BUSCO config file location
export BUSCO_CONFIG_FILE="${busco_config_ini}"

# Export Augustus variable
export PATH="${augustus_bin}:$PATH"
export PATH="${augustus_scripts}:$PATH"
export AUGUSTUS_CONFIG_PATH="${augustus_config_dir}"


# Copy BUSCO config file
cp ${busco_config_default} "${busco_config_ini}"

# Make Augustus directory if it doesn't exist
if [ ! -d "${augustus_dir}" ]; then
  mkdir --parents "${augustus_dir}"
fi

# Copy Augustus config directory
cp --preserve -r ${augustus_orig_config_dir} "${augustus_dir}"

# Edit BUSCO config file
## Set paths to various programs
### The use of the % symbol sets the delimiter sed uses for arguments.
### Normally, the delimiter that most examples use is a slash "/".
### But, we need to expand the variables into a full path with slashes, which screws up sed.
### Thus, the use of % symbol instead (it could be any character that is NOT present in the expanded variable; doesn't have to be "%").
sed -i "/^;cpu/ s/1/${threads}/" "${busco_config_ini}"
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
--in ${transcriptome_fasta} \
--out ${fasta_name} \
--lineage_path ${busco_db} \
--mode transcriptome \
--cpu ${threads} \
--long \
--species ${augustus_species} \
--tarzip \
--augustus_parameters='--progress=true'

# Create checksum for potential verification
md5sum "${transcriptome_fasta}" >> "${fasta_name}".checksum.md5
