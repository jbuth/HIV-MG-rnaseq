#!/bin/bash

## submit a loop of qsub jobs to run FastQC, STAR, and BBDuk

## Setup directories
BASE_DIR="/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021"
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
     "${CODE_DIR}/Step1a_JB_run_FastQC_BBDuk_STAR.sh" "${name}"
  fi
done
