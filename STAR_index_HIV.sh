#!/bin/bash

## Save this script as:
## /path/to/HIV-mg-rnaseq/code/STAR_index_HIV.sh

## To execute, cd into the code folder, then type:
## ./STAR_index_HIV.sh

## Description:
## Create STAR index for HIV 

## ------------ Setup directories ------------- ##

## Base directory: /path/to/
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

## Subdirectories
mkdir -p "${BASE_DIR}/annotation"
cd "${BASE_DIR}/annotation" || exit

## --- Get HIV reference annotation (retrieved 2024-09) ---- ##

wget -r -np -nH --cut-dirs=3 -e robots=off https://ftp.ncbi.nlm.nih.gov/genomes/refseq/viral/Human_immunodeficiency_virus_1/reference/GCF_000864765.1_ViralProj15476/
cd "Human_immunodeficiency_virus_1" || exit
mkdir -p "STAR_index"
cd "/reference/GCF_000864765.1_ViralProj15476/" || exit

## note: I unzipped the following files
# -c: Keeps the original files unchanged (write on standard output, keep original files unchanged)
gunzip -c GCF_000864765.1_ViralProj15476_genomic.fna.gz >GCF_000864765.1_ViralProj15476_genomic.fna 
gunzip -c GCF_000864765.1_ViralProj15476_genomic.gtf.gz >GCF_000864765.1_ViralProj15476_genomic.gtf
gunzip -c GCF_000864765.1_ViralProj15476_genomic.gff.gz >GCF_000864765.1_ViralProj15476_genomic.gff
gunzip -c GCF_000864765.1_ViralProj15476_cds_from_genomic.fna.gz >GCF_000864765.1_ViralProj15476_cds_from_genomic.fna
gunzip -c GCF_000864765.1_ViralProj15476_feature_table.txt.gz >GCF_000864765.1_ViralProj15476_feature_table.txt

## --------- interactive node in a screen ---------- ##
 
screen
qrsh -l h_rt=24:00:00,h_data=16G,highp -pe shared 8

## STAR bin & index
STAR_DIR="${BASE_DIR}/bin/STAR/bin/Linux_x86_64/STAR"

## species reference directory
HIV_DIR="${BASE_DIR}/annotation/Human_immunodeficiency_virus_1"

## genome fasta
GENOME_FA="${HIV_DIR}/reference/GCF_000864765.1_ViralProj15476/GCF_000864765.1_ViralProj15476_genomic.fna"

## annotation gtf (NOTE USING GFF)
ANNO_GTF="${HIV_DIR}/reference/GCF_000864765.1_ViralProj15476/GCF_000864765.1_ViralProj15476_genomic.gff"
## Using gff file for annotation, in STAR call assigned:
	## "exon_id" labels -> --sjdbGTFtagExonParentTranscript "CDS" 
	## "gene" labels -> --sjdbGTFtagExonParentGene "Parent"
  
## Must account for the small HIV genome size with --genomeSAindexNbases 5 
## Round down to choose 5 from -> min(14, log2(GenomeLength=9181)/2 - 1) = 5.58
  
${STAR_DIR} --runThreadN 8 --runMode genomeGenerate \
	--genomeDir "${HIV_DIR}/STAR_index" \
	--genomeFastaFiles "${GENOME_FA}" \
	--sjdbGTFfile "${ANNO_GTF}" \
	--genomeSAindexNbases 5 \
	--sjdbGTFfeatureExon "CDS" \
	--sjdbGTFtagExonParentTranscript "Parent"
