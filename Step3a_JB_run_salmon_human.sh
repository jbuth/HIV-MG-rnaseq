#!/bin/bash

## Running salmon (version 1.10.3; updated 2024-08) in alignment-based mode using STAR (v2.5.4b) Aligned.toTranscriptome.out.bam files

## module command
. /u/local/Modules/default/init/modules.sh

module load conda/23.11.0
conda activate salmon

## base names from the previous qsub loop
name=$1

## project folder (base directory)
BASE_DIR="2"

## Human transcripts 
TRANSCRIPT_FASTA="${BASE_DIR}/annotation/homo_sapiens/gencode.v28.transcripts.fa"

## output Aligned.toTranscriptome.out.bam files from STAR_human
BAM_DIR="${BASE_DIR}/STAR/STAR_human"

## Output directory
SALMON_OUT_DIR="${BASE_DIR}/salmon/salmon_human"

salmon quant --targets ${TRANSCRIPT_FASTA} \
  --libType A \
	--alignments "${BAM_DIR}/${name}Aligned.toTranscriptome.out.bam" \
	--threads 8 \
	--output "${SALMON_OUT_DIR}/${name}" \
	--gencode --seqBias --gcBias

## if this was faster than 10 minutes, sleep for the rest
END=$SECONDS
ELAPSED=$((END-START))
if [ "$ELAPSED" -lt 600 ]; then
  TOSLEEP=$((600 - ELAPSED))
  sleep $TOSLEEP
fi
