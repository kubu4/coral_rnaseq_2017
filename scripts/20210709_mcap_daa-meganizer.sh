#!/bin/bash

# Script to run MEGAN6 "daa2rma" on DIAMOND DAA files from
# 20210611_mcap_diamond_blastx.

# Requires MEGAN mapping file from:
# http://ab.inf.uni-tuebingen.de/data/software/megan6/download/

# Exit script if any command fails
set -e

# MEGAN mapping files
map_db=/home/sam/data/databases/MEGAN/megan-map-Jan2021.db

threads=48

# Programs array
declare -A programs_array
programs_array=(
[daa2rma]="/home/sam/programs/megan/tools/daa-meganizer"
)


# Capture start "time"
# Uses builtin bash variable called ${SECONDS}
start=${SECONDS}

# Create array of DAA R1 files
for daa in *READ1*.daa
do
  daa_array_R1+=("${daa}")
done

# Create array of DAA R2 files
for daa in *READ2*.daa
do
  daa_array_R2+=("${daa}")
done

## Run MEGANIZER

# Capture start "time"
start=${SECONDS}
for index in "${!daa_array_R1[@]}"
do

  # Run daa-meagnizer (preferred to daa2rma; much faster)
  ${programs_array[daa2rma]} \
  --in "${daa_array_R1[index]}" "${daa_array_R2[index]}" \
  --mapDB ${map_db} \
  --threads ${threads} \
  2>&1 | tee --append daa-meganizer_log.txt
done

# Caputure end "time"
end=${SECONDS}

runtime=$((end-start))

# Print MEGANIZER runtime, in seconds

{
  echo ""
  echo "---------------------"
  echo ""
  echo "Total runtime was: ${runtime} seconds"
} >> daa-meganizer_log.txt


# Capture program options
for program in "${!programs_array[@]}"
do
	{
  echo "Program options for ${program}: "
	echo ""
	${programs_array[$program]} --help
	echo ""
	echo ""
	echo "----------------------------------------------"
	echo ""
	echo ""
} &>> program_options.log || true
done