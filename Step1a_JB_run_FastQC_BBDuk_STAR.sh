#!/bin/bash

## project folder (base directory)
BASE_DIR=/u/scratch/j/jbuth/Fregoso_Novitch_Bulk_June2021

## location of fastq files
FASTQ_DIR=${BASE_DIR}/fastq

## BBDuk output files (cleaned fastq)
mkdir -p ${BASE_DIR}/clean_fastq
CLEAN_FASTQ_DIR=${BASE_DIR}/clean_fastq

## STAR output files 
BAM_DIR=${BASE_DIR}/STAR/STAR_human

## full filename was -> S39_d1_4_17_infxn_R848_L001_R1_001.fastq.gz
## name -> S39_d1_4_17_infxn_R848
name="$1"

###### ----- Clean fastq with BBDuk ----- ######

## ---- Using BBDuk version 39.08 for adapter trimming on STAR unmapped output .mate1 .mate2
## ---- ## adapter trimming params -> ref=adapters.fa ktrim=r k=23 mink=11 hdist=1 tpe tbo
## ---- ## quality trimming params -> qtrim=r trimq=10 
## ---- ## quality filtering params -> maq=10

## module command
. /u/local/Modules/default/init/modules.sh

module load conda/23.11.0
conda activate bbmap

## adapters and contaminates to remove 
BBMAP_DIR="/u/home/j/jbuth/.conda/envs/bbmap/opt/bbmap-39.08-0/resources"
ADAPTERS_fa="${BBMAP_DIR}/adapters.fa"
ARTIFACTS_fa="${BBMAP_DIR}/sequencing_artifacts.fa.gz"
SHORT_fa="${BBMAP_DIR}/short.fa"
POLYA_fa="${BBMAP_DIR}/polyA.fa.gz"

echo "Running bbduk on sample: ${name}"

bbduk.sh in="${FASTQ_DIR}/${name}_L001_R1_001.fastq.gz" \
	in2="${FASTQ_DIR}/${name}_L001_R2_001.fastq.gz" \
	out="${CLEAN_FASTQ_DIR}/${name}_R1_clean1.fq" \
	out2="${CLEAN_FASTQ_DIR}/${name}_R2_clean2.fq" \
	ref="${ADAPTERS_fa}","${ARTIFACTS_fa}","${SHORT_fa}","${POLYA_fa}" \
	stats="${CLEAN_FASTQ_DIR}/${name}_stats.txt" \
	threads=6 ktrim=r k=23 \
  mink=11 hdist=1 tpe tbo \
	qtrim=r trimq=10 maq=10

conda deactivate

###### ----- STAR Alignment with clean fastq file pairs ----- ###### 

## location of STAR bin & index
STAR_DIR=/u/project/gandalm/jbuth/bin/STAR/bin/Linux_x86_64/STAR
STAR_INDEX=/u/project/butlersj/jbuth/RefGenome/homo_sapiens/STAR_index
	## files to generate STAR index in /u/project/butlersj/jbuth/RefGenome/homo_sapiens
	## --------> genome.fa -> /Genome/hg38.fa
	## --------> GTF annotation -> /Annotation/gencode.v28.annotation.gtf

echo "Running STAR alignment on sample: ${name}"

"${STAR_DIR}" --genomeDir "${STAR_INDEX}" \
	--readFilesIn "${CLEAN_FASTQ_DIR}/${name}_R1_clean1.fq" "${CLEAN_FASTQ_DIR}/${name}_R2_clean2.fq" \
	--runThreadN 8 \
	--outFileNamePrefix "${BAM_DIR}/${name}" \
	--outSAMtype BAM Unsorted SortedByCoordinate \
	--outBAMsortingThreadN 8 \
	--quantMode TranscriptomeSAM \
	--outReadsUnmapped Fastx

###### ----- Check fastq quality with fastQC ----- ######

echo "Running FastQC on sample: ${name}"

FASTQC_DIR=/u/project/gandalm/jbuth/bin/FastQC/fastqc
FASTQC_OUTPUT="${BASE_DIR}/fastqc"

## -- on original fastq files (raw fastq)
${FASTQC_DIR} "${FASTQ_DIR}/${name}_L001_R1_001.fastq.gz" --outdir "${FASTQC_OUTPUT}/original_fastq"
${FASTQC_DIR} "${FASTQ_DIR}/${name}_L001_R2_001.fastq.gz" --outdir "${FASTQC_OUTPUT}/original_fastq"

## -- on cleaned fastq files (after BBDuk - input for STAR)
${FASTQC_DIR} "${CLEAN_FASTQ_DIR}/${name}_R1_clean1.fq" --outdir "${FASTQC_OUTPUT}/clean_fastq"
${FASTQC_DIR} "${CLEAN_FASTQ_DIR}/${name}_R2_clean2.fq" --outdir "${FASTQC_OUTPUT}/clean_fastq"

## -- on unmapped fastq files (after STAR alignment)
${FASTQC_DIR} "${BAM_DIR}/${name}Unmapped.out.mate1" --outdir "${FASTQC_OUTPUT}/unmapped_fastq"
${FASTQC_DIR} "${BAM_DIR}/${name}Unmapped.out.mate2" --outdir "${FASTQC_OUTPUT}/unmapped_fastq"

echo "Finished sample: ${name}"

## if this was faster than 10 minutes, sleep for the rest
END=$SECONDS
ELAPSED=$((END-START))
if [ "$ELAPSED" -lt 600 ]; then
  TOSLEEP=$((600 - ELAPSED))
  sleep $TOSLEEP
fi
