#!/bin/env bash

# Script to pull subset of Transdecoder complete ORFs proteins
# based on InParanoid ortholog comparison between corals and symbiodinium.

# Exit script if a command fails
set -e


# Use sed to modify InParanoid config file
# Uses the "%" as the substitute delimiter to allow usage of "/" in paths
## Set blastall location
sed -i '/^$blastall = "blastall"/ s%"blastall"%"/home/shared/blast-2.2.17/bin/blastall -a23"%' inparanoid.pl

## Set formatdb location
sed -i '/^$formatdb = "formatdb"/ s%"formatdb"%"/home/shared/blast-2.2.17/bin/formatdb"%' inparanoid.pl

## Set InParanoid to use an out group (change from 0 to 1)
sed -i '/^$use_outgroup = 0/ s%0%1%' inparanoid.pl
