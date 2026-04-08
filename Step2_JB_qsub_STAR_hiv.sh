#!/bin/bash

## submit a loop of qsub jobs to run STAR with HIV index

## project folder (base directory - working in scratch folder for now - make sure to download copy)
BASE_DIR="/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021"

## output unmapped fastq files (aligned to human -> saved unmapped)
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
     "${code}/Step2a_JB_run_STAR_hiv.sh" "${name}"
fi
done
