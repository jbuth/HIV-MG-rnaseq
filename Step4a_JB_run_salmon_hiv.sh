#!/bin/bash

## Running salmon in alignment-based mode using STAR v2.5.4b Aligned.toTranscriptome.out.bam files

## module command
. /u/local/Modules/default/init/modules.sh

module load conda/23.11.0
conda activate salmon

## project folder (base directory - working in scratch folder for now - make sure to download copy)
BASE_DIR="/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021"

## hiv transcripts 
TRANSCRIPT_FASTA="${BASE_DIR}/RefGenome/Human_immunodeficiency_virus_1/reference/GCF_000864765.1_ViralProj15476/GCF_000864765.1_ViralProj15476_cds_from_genomic_edited_for_salmon.fna"

## output Aligned.toTranscriptome.out.bam files from STAR_human
BAM_DIR="${BASE_DIR}/STAR/STAR_hiv"

## Output directory
SALMON_OUT_DIR="${BASE_DIR}/salmon/salmon_hiv"

## this keeps the base names from the previous qsub loop
name="$1"

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
