#!/bin/bash

## Save this script as:
## /path/to/HIV-MG-rnaseq/code/Step2_JB_qsub_STAR_hiv.sh

## To execute, cd into the code folder, then type:
## ./Step2_JB_qsub_STAR_hiv.sh

## Description:
## submit a loop of qsub jobs to run FastQC, STAR (with HIV index), and BBDuk
## qsub runs the script Step2a_JB_run_STAR_hiv.sh

## ------ Setup directories ------- ##

## Base directory: /path/to/
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

## Subdirectories
## output folder unmapped fastq files (aligned to human -> saved unmapped)
UNMAPPED_FASTQ_DIR="${BASE_DIR}/STAR/STAR_human"

## where you want output BAM files from STAR to go
BAM_DIR="${BASE_DIR}/STAR/STAR_hiv"

## location of your code.sh files
code="${BASE_DIR}/code"

cd "$UNMAPPED_FASTQ_DIR" || exit

for file in "${UNMAPPED_FASTQ_DIR}"/*Unmapped.out.mate1; do

name=$(basename "$file" Unmapped.out.mate1)

if ! [ -s "${BAM_DIR}/${name}*.bam" ]; then

   echo "${name}"Unmapped.out.mate1 "${name}"Unmapped.out.mate2

   qsub \
     -o "${code}/log" \
     -e "${code}/log" \
     -l h_rt=1:00:00,h_data=16G,highp \
     -pe shared 8 \
     "${code}/Step2a_JB_run_STAR_hiv.sh" "${name}" "${BASE_DIR}"
fi
done
