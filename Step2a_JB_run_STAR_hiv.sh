#!/bin/bash

## After alignment to human, now align the unmapped reads with the HIV index

## project folder (base directory)
BASE_DIR="/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021"

## output unmapped fastq files (aligned to human -> saved unmapped)
UNMAPPED_FASTQ_DIR="${BASE_DIR}/STAR/STAR_human"

## STAR output files 
BAM_DIR="${BASE_DIR}/STAR/STAR_hiv"

## original -> S39_d1_4_17_infxn_R848Unmapped.out.mate1
## name -> S39_d1_4_17_infxn_R848
name="$1"

###### ----- STAR Alignment to HIV with clean fastq file pairs ----- ###### 

## location of STAR bin (version STAR_2.5.4b) & HIV index
STAR_DIR="/u/project/gandalm/jbuth/bin/STAR/bin/Linux_x86_64/STAR"
STAR_INDEX="${BASE_DIR}/RefGenome/Human_immunodeficiency_virus_1/STAR_index_HIV"

${STAR_DIR} --genomeDir "${STAR_INDEX}" \
	--readFilesIn "${UNMAPPED_FASTQ_DIR}/${name}Unmapped.out.mate1" "${UNMAPPED_FASTQ_DIR}/${name}Unmapped.out.mate2" \
	--runThreadN 8 \
	--outFileNamePrefix "${BAM_DIR}/${name}" \
	--outSAMtype BAM Unsorted \
	--quantMode TranscriptomeSAM

## if this was faster than 10 minutes, sleep for the rest
END=$SECONDS
ELAPSED=$((END-START))
if [ "$ELAPSED" -lt 600 ]; then
  TOSLEEP=$((600 - ELAPSED))
  sleep $TOSLEEP
fi
