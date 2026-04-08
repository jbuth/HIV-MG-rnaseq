#!/bin/bash

## Running salmon (version 1.10.3; updated 2024-08) in alignment-based mode using STAR (v2.5.4b) Aligned.toTranscriptome.out.bam files

## module command
. /u/local/Modules/default/init/modules.sh

module load conda/23.11.0
conda activate salmon

## this keeps the base names from the previous qsub loop
name="$1"

## project folder (base directory)
BASE_DIR="2"

## hiv transcripts 
TRANSCRIPT_FASTA="${BASE_DIR}/annotation/Human_immunodeficiency_virus_1/reference/GCF_000864765.1_ViralProj15476/GCF_000864765.1_ViralProj15476_cds_from_genomic_edited_for_salmon.fna"

## output Aligned.toTranscriptome.out.bam files from STAR_human
BAM_DIR="${BASE_DIR}/STAR/STAR_hiv"

## Output directory
SALMON_OUT_DIR="${BASE_DIR}/salmon/salmon_hiv"

salmon quant --targets "${TRANSCRIPT_FASTA}" --libType ISR \
	--alignments "${BAM_DIR}/${name}Aligned.toTranscriptome.out.bam" \
	--threads 8 \
	--output "${SALMON_OUT_DIR}/${name}" \
	--seqBias --gcBias

## if this was faster than 10 minutes, sleep for the rest
END=$SECONDS
ELAPSED=$((END-START))
if [ "$ELAPSED" -lt 600 ]; then
  TOSLEEP=$((600 - ELAPSED))
  sleep $TOSLEEP
fi
