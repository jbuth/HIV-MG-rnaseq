# HIV-MG-rnaseq

This repository contains a bulk RNA-seq processing pipeline (FASTQ → count matrix) used in Chapter 7 of:

Buth, J. E. (2025). Modeling neurodevelopment and disease using human pluripotent stem cells and mouse models. UCLA. ProQuest ID: Buth_ucla_0031D_23855. Merritt ID: ark:/13030/m5xn01g0. Retrieved from https://escholarship.org/uc/item/9794n656

## Dataset Description:
- Human pluripotent stem cell derived microglia were infected with HIV and collected for bulk RNA-seq 1, 2, 4, and 6 days post-infection
- Human Annotation:
    - hg38.fa
    - gencode.v28.annotation.gtf
    - gencode.v28.transcripts.fa
- HIV Annotation:
    - GCF_000864765.1_ViralProj15476_genomic.fna
    - GCF_000864765.1_ViralProj15476_genomic.gff
    - GCF_000864765.1_ViralProj15476_cds_from_genomic.fna

## Data Availability:
- The raw and processed dataset will be available at GEO after publication
- Supplementary tables from Chapter 7 include results from pathway analysis (Table 7-1), external gene list enrichments (Table 7-2), and differential expression (Table 7-5)

## Pipeline Overview
FASTQ → BBDuk (quality control) → STAR (human alignment) → Salmon (human quantification)  
→ Unmapped reads → STAR (HIV alignment) → Salmon (HIV quantification)  
→ Tximport (merge human + HIV counts)

## Code Overview:
- Step1: FastQC, BBDuk, and STAR alignment to human genome (FASTQ → cleaned FASTQ → mapped/unmapped reads)
- Step2: STAR alignment of unmapped reads to HIV genome
- Step3: Salmon quantification of human transcriptome (human BAM → counts)
- Step4: Salmon quantification of HIV transcriptome (HIV BAM → counts)
- Step5: R script to merge human and HIV quantifications into a single count matrix

## Directory Structure:
Organized to separate raw data, processing scripts, and downstream analysis.
```plaintext
- HIV-MG-rnaseq/
    - code/
      - log
      - Step1_JB_qsub_FastQC_BBDuk_STAR.sh
      - Step1a_JB_run_FastQC_BBDuk_STAR.sh
      - Step2_JB_qsub_STAR_hiv.sh
      - Step2a_JB_run_STAR_hiv.sh
      - Step3_JB_qsub_salmon_human.sh
      - Step3a_JB_run_salmon_human.sh
      - Step4_JB_qsub_salmon_hiv.sh
      - Step4a_JB_run_salmon_hiv.sh
    - bin/
      - STAR
    - annotation/
      - homo_sapiens/
        - STAR_index/
      - Human_immunodeficiency_virus_1
        - STAR_index/
    - fastq/        # raw fastq files
    - clean_fastq/  # BBduk output files
    - STAR/         # STAR output files
      - STAR_human
      - STAR_hiv
    - fastqc/       # FastQC output files
      - original_fastq/
      - clean_fastq/
      - unmapped_fastq/
    - salmon/       # salmon output files
      - salmon_human
      - salmon_hiv
    - R/
      - Step5_JB_Tximport.R
```

