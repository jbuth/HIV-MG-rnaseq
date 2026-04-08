#!/bin/bash

## Save this script as:
## /path/to/HIV-MG-rnaseq/code/Step4_JB_qsub_salmon_hiv.sh

## To execute, cd into the code folder, then type:
## ./Step4_JB_qsub_salmon_hiv.sh

## Description:
## submit a loop of qsub jobs to run salmon with hiv transcripts
## qsub runs the script Step4a_JB_run_salmon_hiv.sh

## ------ Setup directories ------- ##

## Base directory: /path/to/
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

## output Aligned.toTranscriptome.out.bam files from STAR_hiv
BAM_DIR="${BASE_DIR}/STAR/STAR_hiv"

## location of your code.sh files
code="${BASE_DIR}/code"

cd "$BAM_DIR" || exit

for file in "${BAM_DIR}"/*Aligned.toTranscriptome.out.bam; do

  name=$(basename "$file" Aligned.toTranscriptome.out.bam)
  echo "${name}Aligned.toTranscriptome.out.bam"
  qsub \
    -o "${code}/log" \
    -e "${code}/log" \
    -l h_rt=1:00:00,h_data=8G,highp \
    -pe shared 8 \
    "${code}/Step4a_JB_run_salmon_hiv.sh" "${name}" "${BASE_DIR}"

done
