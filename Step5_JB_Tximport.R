## -- Tximport (Import files from salmon) -- ##
## NOTE:
## This script represents the core analysis workflow used in this project.
## Some paths (e.g., output directories) should be defined by the user.
## clear workspace

rm(list=ls())
options(stringsAsFactors = FALSE)

# working dir is base directory of project folder

    # list.files()
        # [1] "clean_fastq" "code"        "fastq"      
        # [4] "fastqc"      "annotation"  
        # [7] "salmon"      "STAR" 

## --- tx2gene annotations for human & hiv --- ##

# devtools::install_github("jmw86069/splicejam")
library(splicejam)

# load human GTF ####
human.gtf.file = "RefGenome/homo_sapiens/Annotation/gencode.v28.annotation.gtf"
tx2gene.human = makeTx2geneFromGtf(human.gtf.file)

# load hiv GTF ####
hiv.gtf.file = "RefGenome/Human_immunodeficiency_virus_1/reference/GCF_000864765.1_ViralProj15476/GCF_000864765.1_ViralProj15476_genomic.gtf"
tx2gene.hiv = makeTx2geneFromGtf(
  hiv.gtf.file,
  geneAttrNames = c("gene_id", "db_xref", "gene", "gene_biotype"),
  txAttrNames = c("transcript_id", "product", "protein_id", "note"),
  geneFeatureType = "gene", # in GTFcol3 "feature", is gene (default="gene")
  txFeatureType = "CDS") # in GTFcol3, which "feature" is transcript (default="transcript" or "mRNA")

      # For HIV, col3 has gene, CDS, start_codon, or stop_codon
      # For HIV, col9 has:
          # For CDS = gene_id "HIVgp1", transcript_id "unassigned_transcript_2", gbkey "CDS", 
                # gene "gag", locus_tag "HIV1gp2", 
                # product "Pr55(Gag)", protein_id "NP_O57850.1", exon_number "1"
                # sometimes also has exception or note
          # For gene = gene_id, transcript_id, db_xref, gbkey, gene, gene_biotype, locus_tag
                # leaving off locus_tag, is name as gene_id

# Put in order by gene_id HIV1gp1-HIV1gp10
tx2gene.hiv = tx2gene.hiv[order(tx2gene.hiv$protein_id, decreasing=F),]

# adding some additional info to the note column & combining product/protein_id
tx2gene.hiv$note[tx2gene.hiv$gene=="asp"] = "antisense gene asp is unique to group M strains and has unknown function - Pavesi 2024 PMID:38230940 full ORF associated with faster disease progression"
tx2gene.hiv$additional_info = paste0("alt_name:", tx2gene.hiv$gene_id, " / db_xef:", tx2gene.hiv$db_xref, " / product:", tx2gene.hiv$product, " / protein_id:", tx2gene.hiv$protein_id, " / note:", tx2gene.hiv$note)

    # head(tx2gene.hiv, 2)
        #                         gene_id    gene db_xref
        # unassigned_transcript_1 HIV1gp1 gag-pol GeneID:155348
        # unassigned_transcript_2 HIV1gp2     gag GeneID:155030
        #                           gene_biotype           transcript_id
        # unassigned_transcript_1 protein_coding unassigned_transcript_1
        # unassigned_transcript_2 protein_coding unassigned_transcript_2
        #                           product  protein_id note
        # unassigned_transcript_1   Gag-Pol NP_057849.4 Pr160
        # unassigned_transcript_2 Pr55(Gag) NP_057850.1
     
    # head(tx2gene.human, 3)
        #                              gene_id gene_name      gene_type
        # ENST00000612152.4 ENSG00000000003.14    TSPAN6 protein_coding
        # ENST00000373020.8 ENSG00000000003.14    TSPAN6 protein_coding
        # ENST00000614008.4 ENSG00000000003.14    TSPAN6 protein_coding
        #                       transcript_id transcript_type
        # ENST00000612152.4 ENST00000612152.4  protein_coding
        # ENST00000373020.8 ENST00000373020.8  protein_coding
        # ENST00000614008.4 ENST00000614008.4  protein_coding

# Will need to add columns and match up for single geneAnno
# Note for hiv, salmon used the HIVgp1, HIVgp2 names as transcript_ids

# to combine want columns
    # "gene_id" -> hiv db_xref / human gene_id
    # "gene_name" -> hiv gene / human gene_name
    # "gene_biotype" -> same for both
    # "transcript_id" -> hiv / human transcript_id
    # "transcript_type" -> hiv - use gene_biotype again / human transcript_type
    # "additional_info" -> combine rest of hiv gene info (product, protein_id, and note)

## --- Load hiv quant.sf files from salmon --- ##

library(tximport);

# HIV ####

# salmon/salmon_hiv/sample_name/quant.sf
hiv.files = paste0("salmon/salmon_hiv/", list.files("salmon/salmon_hiv"), "/quant.sf") 

# name each file so tximport adds names to count matrices
names(hiv.files) = list.files("salmon/salmon_hiv")

    # head quant.sf
        # Name	Length	EffectiveLength	TPM	NumReads
        # gene-HIV1gp2	1503	1104.000	0.000000	0.000
        # gene-HIV1gp1	4308	5802.979	207242.552426	85.974
        # gene-HIV1gp3	579	387.264	144482.520723	4.000
        # gene-HIV1gp4	291	169.000	0.000000	0.000
        # gene-HIV1gp5	261	146.846	95257.974702	1.000
        # gene-HIV1gp6	351	196.000	0.000000	0.000
        # gene-HIV1gp7	249	131.000	0.000000	0.000
        # gene-HIV1gp8	2571	2483.986	219768.742125	39.026
        # gene-HIV1gp10	570	258.825	54045.035794	1.000

# need 2 things:
    # (1) paths to quant.sf files
    # (2) tx2gene annotation df (transcript_id, gene_id)
            # transcript_id needs to match what transcript IDs were used for salmon. 
            # Exact column names transcript_id/gene_id don't matter, but needs to be in that order 

# need to match "gene-HIV1gp1" pattern for tx2gene
tx2gene = data.frame(transcript_id = paste0("gene-", tx2gene.hiv$gene_id), 
                     gene_id = tx2gene.hiv$gene)

txi.salmon.hiv <- tximport(files = hiv.files, 
                           type = "salmon", 
                           tx2gene = tx2gene,
                           txIn = TRUE, txOut = FALSE, # input is transcript, want gene counts
                           countsFromAbundance = "no") # wait to norm by library size with human+hiv counts

    # summary(txi.salmon.hiv)
    #                     Length Class  Mode     
    # abundance           460    -none- numeric  
    # counts              460    -none- numeric  
    # length              460    -none- numeric  
    # countsFromAbundance   1    -none- character  # -- no
    # head(txi.salmon.hiv$counts)
        #         S01_d1_4_11_infxn_uninf S02_d1_4_11_infxn_AD8_low
        # asp                       1.000                     4.000
        # env                      39.026                   118.574
        # gag                       0.000                    36.990

# Get gene lengths from one of the quant.sf files
hiv.len.info = read.delim(hiv.files[[1]])
idx = match(tx2gene.hiv$gene_id, gsub(pattern="gene-", replacement="", hiv.len.info$Name))
hiv.len.info = hiv.len.info[idx, ]
tx2gene.hiv$cds_length = hiv.len.info$Length

## --- Load human quant.sf files from salmon --- ##

# Human ####

# salmon/salmon_human/sample_name/quant.sf
human.files = paste0("salmon/salmon_human/", list.files("salmon/salmon_human"), "/quant.sf") 

# name each file so tximport adds names to count matrices
names(human.files) = list.files("salmon/salmon_human")

# need 2 things:
    # (1) paths to quant.sf files
    # (2) tx2gene annotation df (transcript_id, gene_id)
            # transcript_id needs to match what transcript IDs were used for salmon. 
            # Exact column names transcript_id/gene_id don't matter, but needs to be in that order 

# using gencode v28 ensembl_transcript_id/ensembl_gene_id 
hs.tx2gene = data.frame(transcript_id = tx2gene.human$transcript_id, 
                     gene_id = tx2gene.human$gene_id)
    # head(hs.tx2gene)
        #       transcript_id            gene_id
        # 1 ENST00000612152.4 ENSG00000000003.14
        # 2 ENST00000373020.8 ENSG00000000003.14
        # 3 ENST00000614008.4 ENSG00000000003.14

txi.salmon.human <- tximport(files = human.files, 
                             type = "salmon", 
                             tx2gene = hs.tx2gene,
                             txIn = TRUE, txOut = FALSE, # input is transcript, want gene counts
                             countsFromAbundance = "no") # wait to norm by library size with hiv counts 

## --- Get additional annotations with biomaRt --- ##

library(biomaRt);

# Get gene cds lengths for human
getinfo <- c("ensembl_transcript_id","ensembl_gene_id", "external_gene_name",
             "description", "hgnc_symbol","entrezgene_id", 
             "mirbase_accession", "mirbase_id",
             "chromosome_name", "start_position", "end_position",
             "transcript_count", "transcript_start", "transcript_end", "transcript_length", 
             "percentage_gene_gc_content", "gene_biotype",
             "family", "family_description")

# GENCODE version 28 corresponds to Ensembl 92
ensembl = useEnsembl(biomart="ensembl", 
                     dataset="hsapiens_gene_ensembl", 
                     version=97) # available archives go 77,80,97,98
                    #mirror="uswest") # if needed can change mirror
attributePages(ensembl)
    # [1] "feature_page" "structure"    "homologs"     "snp"         
    # [5] "snp_somatic"  "sequences"
attributes <- listAttributes(ensembl, page = "feature_page")
dim(attributes)
    # [1] 204   3

getinfo1 <- c("ensembl_gene_id", "external_gene_name",
             "description", "hgnc_symbol","entrezgene_id", 
             "chromosome_name", "start_position", "end_position")
             
getinfo2 <- c("ensembl_gene_id", "external_gene_name",
              "mirbase_accession", "mirbase_id", 
              "percentage_gene_gc_content", "gene_biotype", 
              "family", "family_description")

getinfo4 <- c('ensembl_gene_id','transcript_count','cds_length')

bm1 <- getBM(attributes = getinfo1,
             mart = ensembl)
dim(bm1) # [1] 67201     8

bm2 <- getBM(attributes = getinfo2,
             mart = ensembl)
dim(bm2) # [1] 83857     8

bm4 <- getBM(attributes = getinfo4,
             mart = ensembl)
dim(bm4) # [1] 247909      7

# combine to 1 bm
idx = match(substr(rownames(txi.salmon.human$counts),1,15), bm4$ensembl_gene_id)

bm4.exp = bm4[idx, ]
    #       ensembl_gene_id transcript_count cds_length
    # 18680 ENSG00000000003                5        738
    # 18631 ENSG00000000005                2        954
    # 64294 ENSG00000000419                6        783
    # 21312 ENSG00000000457                5       2067

idx = match(substr(rownames(txi.salmon.human$counts),1,15), bm2$ensembl_gene_id)
bm2.exp = bm2[idx, ]

idx = match(substr(rownames(txi.salmon.human$counts),1,15), bm1$ensembl_gene_id)
bm1.exp = bm1[idx, ]

bm.final = data.frame(ensembl_gene_id=bm1.exp$ensembl_gene_id, 
                      external_gene_name=bm1.exp$external_gene_name, 
                      description=bm1.exp$description,
                      gene_biotype=bm2.exp$gene_biotype, 
                      percentage_gene_gc_content=bm2.exp$percentage_gene_gc_content,
                      transcript_count=bm4.exp$transcript_count, 
                      cds_length=bm4.exp$cds_length, 
                      chromosome_name= bm1.exp$chromosome_name,
                      family=bm2.exp$family, 
                      family_description=bm2.exp$family_description,
                      hgnc_symbol=bm1.exp$hgnc_symbol, 
                      entrezgene_id=bm1.exp$entrezgene_id,
                      mirbase_accession=bm2.exp$mirbase_accession, 
                      mirbase_id=bm2.exp$mirbase_id)

## --- Combine human and hiv annotations to one geneAnno --- ##

hiv.geneAnno = tx2gene.hiv
human.geneAnno = bm.final

hiv.formatted = data.frame(ensembl_gene_id=hiv.geneAnno$gene,
                           external_gene_name=hiv.geneAnno$gene,
                           description=hiv.geneAnno$additional_info,
                           gene_biotype=hiv.geneAnno$gene_biotype,
                           percentage_gene_gc_content=rep(NA, nrow(hiv.geneAnno)),
                           transcript_count=rep(1, nrow(hiv.geneAnno)),
                           cds_length=hiv.geneAnno$cds_length,
                           chromosome_name=rep(NA, nrow(hiv.geneAnno)),
                           family=rep(NA, nrow(hiv.geneAnno)),
                           family_description=rep(NA, nrow(hiv.geneAnno)),
                           hgnc_symbol=rep(NA, nrow(hiv.geneAnno)),
                           entrezgene_id=rep(NA, nrow(hiv.geneAnno)),
                           mirbase_accession=rep(NA, nrow(hiv.geneAnno)),
                           mirbase_id=rep(NA, nrow(hiv.geneAnno)))
        
geneAnno = rbind(hiv.formatted, human.geneAnno)

# remove any NAs
geneAnno = geneAnno[complete.cases(geneAnno$ensembl_gene_id),]

# some gene_ids are duplicated, checked a few and appear to be exactly the same, will remove duplicates
duplicate.genes = geneAnno$ensembl_gene_id[duplicated(geneAnno)]
idx = match(duplicate.genes, geneAnno$ensembl_gene_id)
geneAnno = geneAnno[-idx, ]

    # dim(geneAnno)
        # [1] 58034    14

## --- Save aggregated counts & geneAnno --- ##

save(txi.salmon.hiv, txi.salmon.human, geneAnno,
     file="R/HIV-MG_2021_RNAseq/data/HIV-MG_2021_RNAseq_raw_counts_salmon.RData")

## --- Create df of sample metadata --- #

datMeta = data.frame(Sample = colnames(txi.salmon.human$counts))

datMeta$Infection_date = rep(NA, nrow(datMeta))
datMeta$Infection_date[grep(pattern="4_11", datMeta$Sample)] = "4_11"
datMeta$Infection_date[grep(pattern="4_17", datMeta$Sample)] = "4_17"
datMeta$Infection_date[grep(pattern="4_25", datMeta$Sample)] = "4_25"
datMeta$Infection_date[grep(pattern="4_26", datMeta$Sample)] = "4_26"
datMeta$Infection_date = factor(datMeta$Infection_date, levels=c("4_11", "4_17", "4_25", "4_26"))
datMeta$Time = rep(NA, nrow(datMeta))
datMeta$Time[grep(pattern="d1", datMeta$Sample)] = "d1"
datMeta$Time[grep(pattern="d2", datMeta$Sample)] = "d2"
datMeta$Time[grep(pattern="d4", datMeta$Sample)] = "d4"
datMeta$Time[grep(pattern="d6", datMeta$Sample)] = "d6"
datMeta$Time = factor(datMeta$Time, levels=c("d1", "d2", "d4", "d6"))

datMeta$Condition = rep(NA, nrow(datMeta))
datMeta$Condition[grep(pattern="uninf", datMeta$Sample)] = "Uninf"
datMeta$Condition[grep(pattern="R848", datMeta$Sample)] = "R848"
datMeta$Condition[grep(pattern="dEnv", datMeta$Sample)] = "dEnv"
datMeta$Condition[grep(pattern="AD8_low", datMeta$Sample)] = "AD8_low"
datMeta$Condition[grep(pattern="AD8_high", datMeta$Sample)] = "AD8_high"
datMeta$Condition = factor(datMeta$Condition, levels=c("Uninf", "R848", "dEnv", "AD8_low", "AD8_high"))

datMeta$Time_Condition = paste0(datMeta$Time, "_", datMeta$Condition)

## --- Format and combine human & hiv counts --- ##

hiv.counts = txi.salmon.hiv$counts
human.counts = txi.salmon.human$counts

# removing version #s from ensembl gene ids
rownames(human.counts) = substr(rownames(human.counts),1,15)

# will take the first record for any duplicates by using match excluding the hiv genes
idx = match(geneAnno$ensembl_gene_id[11:nrow(geneAnno)], substr(rownames(human.counts),1,15))
human.counts = human.counts[idx, ]

# combine to one df
all.counts = rbind(hiv.counts, human.counts)
    # dim(all.counts) # [1] 58391    46
# setequal(geneAnno$ensembl_gene_id, rownames(all.counts))
    # [1] TRUE

datMeta$HIV_counts = colSums(hiv.counts)
datMeta$Human_counts = colSums(human.counts)
datMeta$Total_counts = colSums(all.counts)
datMeta$Percent_HIV_counts = (datMeta$HIV_counts/datMeta$Total_counts)*100
datMeta$Percent_human_counts = (datMeta$Human_counts/datMeta$Total_counts)*100

# colMeans(datMeta[,c("HIV_counts", "Human_counts", "Total_counts", "Percent_HIV_counts", "Percent_human_counts")])
    #   HIV_counts Human_counts Total_counts  Percent_HIV_counts Percent_human_counts  
    #     95,882.5   20,956,620.1   21,052,502.6   0.4626357           99.53736


## --- Save final gene annotation, metadata, and full count matrix --- ##

datExpr_unfilt = all.counts

save(geneAnno, datMeta, datExpr,
     file="R/data/HIV-MG-rnaseq_unfiltered_counts.RData")

