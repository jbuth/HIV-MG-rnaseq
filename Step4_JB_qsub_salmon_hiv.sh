#!/bin/bash

## submit a loop of qsub jobs to run salmon with hiv transcripts

## project folder (base directory - working in scratch folder for now - make sure to download copy)
BASE_DIR="/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021"

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
    "${code}/Step4a_JB_run_salmon_hiv.sh" "${name}"

done
