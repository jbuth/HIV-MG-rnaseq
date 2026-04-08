#!/bin/bash

## Running salmon in alignment-based mode using STAR v2.5.4b Aligned.toTranscriptome.out.bam files

## module command
. /u/local/Modules/default/init/modules.sh

module load conda/23.11.0
conda activate salmon

## Human transcripts 
TRANSCRIPT_FASTA="/u/project/butlersj/jbuth/RefGenome/homo_sapiens/Annotation/gencode.v28.transcripts.fa"

## project folder (base directory - working in scratch folder for now - make sure to download copy)
BASE_DIR="/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021"

## output Aligned.toTranscriptome.out.bam files from STAR_human
BAM_DIR="${BASE_DIR}/STAR/STAR_human"

## Output directory
SALMON_OUT_DIR="${BASE_DIR}/salmon/salmon_human"

## this keeps the base names from the previous qsub loop
name=$1

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
