# Rohan Krishnamurthi Project: COAD data retrieval

# Install Packages
library(tidyverse)
library(shiny)
library(DT)
library(plotly)
library(bslib)
library(dplyr)

# Survival package
# install.packages("survminer")
library(survminer)

# Set working directory and import relevant data
getwd()

# OPTION A: TCGAbiolinks package
# Install relevant packages
#if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
#BiocManager::install(version = "3.20")

#BiocManager::install("BioinformaticsFMRP/TCGAbiolinksGUI.data")
#BiocManager::install("BioinformaticsFMRP/TCGAbiolinks")

# Load package
library(TCGAbiolinks)
# browseVignettes("TCGAbiolinks") # load documentation


query_1 <- GDCquery(
  project = "TCGA-COAD", 
  data.category = "Clinical",
  data.type = "Clinical Supplement", 
  data.format = "BCR Biotab"
)

GDCdownload(query_1)
clinical_BCRtab_all <- GDCprepare(query_1)
names(clinical_BCRtab_all)

# Create individual datasets
clinical_follow_up_v1.0_coad <- clinical_BCRtab_all$clinical_follow_up_v1.0_coad
clinical_radiation_coad <- clinical_BCRtab_all$clinical_radiation_coad
clinical_nte_coad <- clinical_BCRtab_all$clinical_nte_coad
clinical_omf_v4.0_coad <- clinical_BCRtab_all$clinical_omf_v4.0_coad
clinical_follow_up_v1.0_nte_coad <- clinical_BCRtab_all$clinical_follow_up_v1.0_nte_coad
clinical_patient_coad <- clinical_BCRtab_all$clinical_patient_coad
clinical_drug_coad <- clinical_BCRtab_all$clinical_drug_coad


# Save individual datasets
write.csv(clinical_follow_up_v1.0_coad, file = "data/clinical_follow_up_v1.0_coad.csv", row.names = FALSE)
write.csv(clinical_radiation_coad, file = "data/clinical_radiation_coad.csv", row.names = FALSE)
write.csv(clinical_nte_coad, file = "data/clinical_nte_coad.csv", row.names = FALSE)
write.csv(clinical_omf_v4.0_coad, file = "data/clinical_omf_v4.0_coad.csv", row.names = FALSE)
write.csv(clinical_follow_up_v1.0_nte_coad, file = "data/clinical_follow_up_v1.0_nte_coad.csv", row.names = FALSE)
write.csv(clinical_patient_coad, file = "data/clinical_patient_coad.csv", row.names = FALSE)
write.csv(clinical_drug_coad, file = "data/clinical_drug_coad.csv", row.names = FALSE)


