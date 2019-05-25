#!/bin/env bash

# Script to pull subset of Transdecoder complete ORFs proteins
# based on InParanoid ortholog comparison between corals and symbiodinium.

# Exit script if a command fails
set -e
# Save current directory as working directory.
wd="$(pwd)"
