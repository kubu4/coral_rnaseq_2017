#!/bin/bash
## Job Name
#SBATCH --job-name=transdecoder_montipora
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
#SBATCH --workdir=/gscratch/scrubbed/samwhite/outputs/20190528_transdecoder_montipora_all

# Load Python Mox module for Python module availability

module load intel-python3_2017

# Document programs in PATH (primarily for program version ID)

date >> system_path.log
echo "" >> system_path.log
echo "System PATH for $SLURM_JOB_ID" >> system_path.log
echo "" >> system_path.log
printf "%0.s-" {1..10} >> system_path.log
echo ${PATH} | tr : \\n >> system_path.log


wd="$(pwd)"


# Paths to input/output files
blastp_out_dir="${wd}/blastp_out"
transdecoder_out_dir="${wd}/Trinity.fasta.transdecoder_dir"
pfam_out_dir="${wd}/pfam_out"
blastp_out="${blastp_out_dir}/blastp.outfmt6"

pfam_out="${pfam_out_dir}/pfam.domtblout"
lORFs_pep="${transdecoder_out_dir}/longest_orfs.pep"
pfam_db="/gscratch/srlab/programs/Trinotate-v3.1.1/admin/Pfam-A.hmm"
sp_db="/gscratch/srlab/programs/Trinotate-v3.1.1/admin/uniprot_sprot.pep"

trinity_fasta="/gscratch/scrubbed/samwhite/data/montipora//Trinity.fasta"

# Paths to programs
blast_dir="/gscratch/srlab/programs/ncbi-blast-2.8.1+/bin"
blastp="${blast_dir}/blastp"
hmmer_dir="/gscratch/srlab/programs/hmmer-3.2.1/src"
hmmscan="${hmmer_dir}/hmmscan"
transdecoder_dir="/gscratch/srlab/programs/TransDecoder-v5.5.0"
transdecoder_lORFs="${transdecoder_dir}/TransDecoder.LongOrfs"
transdecoder_predict="${transdecoder_dir}/TransDecoder.Predict"

# Make output directories
mkdir ${blastp_out_dir}
mkdir ${pfam_out_dir}

# Extract long open reading frames
${transdecoder_lORFs} \
-t ${trinity_fasta}

# Run blastp on long ORFs
${blastp} \
-query ${lORFs_pep} \
-db ${sp_db} \
-max_target_seqs 1 \
-outfmt 6 \
-evalue 1e-5 \
-num_threads 28 \
> ${blastp_out}

# Run pfam search
${hmmscan} \
--cpu 28 \
--domtblout ${pfam_out} \
${pfam_db} \
${lORFs_pep}

# Run Transdecoder with blastp and Pfam results
${transdecoder_predict} \
-t ${trinity_fasta} \
--retain_pfam_hits ${pfam_out} \
--retain_blastp_hits ${blastp_out}
