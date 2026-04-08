#!/bin/bash

## Save this script as:
## /path/to/HIV-MG-rnaseq/code/Step1_JB_qsub_FastQC_BBDuk_STAR.sh

## To execute, cd into the code folder, then type:
## ./Step1_JB_qsub_FastQC_BBDuk_STAR.sh

## Description:
## submit a loop of qsub jobs to run FastQC, STAR, and BBDuk
## qsub runs the script Step1a_JB_run_FastQC_BBDuk_STAR.sh

## ------ Setup directories ------- ##

## Base directory: /path/to/
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

## Subdirectories
FASTQ_DIR="${BASE_DIR}/fastq"

mkdir -p "${BASE_DIR}/STAR/STAR_human"
OUTPUT_DIR="${BASE_DIR}/STAR/STAR_human"

CODE_DIR="${BASE_DIR}/code"
mkdir -p "${CODE_DIR}/log"

cd "$FASTQ_DIR" || exit 

for file in *_L001_R1_001.fastq.gz; do

  name=$(basename "$file" _L001_R1_001.fastq.gz)
  
  if ! [ -s "${OUTPUT_DIR}/${name}*.bam" ]; then
  
   echo "${name}_L001_R1_001.fastq.gz" "${name}_L001_R2_001.fastq.gz"
   
   qsub \
     -o "${CODE_DIR}/log" \
     -e "${CODE_DIR}/log" \
     -l h_rt=12:00:00,h_data=16G,highp \
     -pe shared 8 \
     "${CODE_DIR}/Step1a_JB_run_FastQC_BBDuk_STAR.sh" "${name}" "${BASE_DIR}"
  fi
done
