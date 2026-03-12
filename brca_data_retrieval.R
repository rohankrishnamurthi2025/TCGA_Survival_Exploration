# Rohan Krishnamurthi Project: data retrieval

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


# Alternate option to download the data
#install.packages("RTCGA.clinical")
#library(RTCGA.clinical)
#data(clinical_BRCA)
#head(clinical_BRCA)


# OPTION A: TCGAbiolinks package
# Install relevant packages
#if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
#BiocManager::install(version = "3.20")

#BiocManager::install("BioinformaticsFMRP/TCGAbiolinksGUI.data")
#BiocManager::install("BioinformaticsFMRP/TCGAbiolinks")

# Load package
library(TCGAbiolinks)
# browseVignettes("TCGAbiolinks") # load documentation


# MY PERSONAL ATTEMPT
query_1 <- GDCquery(
  project = "TCGA-BRCA", 
  data.category = "Clinical",
  data.type = "Clinical Supplement", 
  data.format = "BCR Biotab"
)

GDCdownload(query_1)
clinical_BCRtab_all <- GDCprepare(query_1)
# names(clinical_BCRtab_all)

# Create individual datasets
clinical_nte_brca <- clinical_BCRtab_all$clinical_nte_brca
clinical_follow_up_v4.0_nte_brca <- clinical_BCRtab_all$clinical_follow_up_v4.0_nte_brca
clinical_drug_brca <- clinical_BCRtab_all$clinical_drug_brca
clinical_follow_up_v1.5_brca <- clinical_BCRtab_all$clinical_follow_up_v1.5_brca
clinical_follow_up_v4.0_brca <- clinical_BCRtab_all$clinical_follow_up_v4.0_brca
clinical_radiation_brca <- clinical_BCRtab_all$clinical_radiation_brca
clinical_follow_up_v2.1_brca <- clinical_BCRtab_all$clinical_follow_up_v2.1_brca
clinical_patient_brca <- clinical_BCRtab_all$clinical_patient_brca
clinical_omf_v4.0_brca <- clinical_BCRtab_all$clinical_omf_v4.0_brca

# Save individual datasets
write.csv(clinical_nte_brca, file = "data/clinical_nte_brca.csv", row.names = FALSE)
write.csv(clinical_follow_up_v4.0_nte_brca, file = "data/clinical_follow_up_v4.0_nte_brca.csv", row.names = FALSE)
write.csv(clinical_drug_brca, file = "data/clinical_drug_brca.csv", row.names = FALSE)
write.csv(clinical_follow_up_v1.5_brca, file = "data/clinical_follow_up_v1.5_brca.csv", row.names = FALSE)
write.csv(clinical_follow_up_v4.0_brca, file = "data/clinical_follow_up_v4.0_brca.csv", row.names = FALSE)
write.csv(clinical_radiation_brca, file = "data/clinical_radiation_brca.csv", row.names = FALSE)
write.csv(clinical_follow_up_v2.1_brca, file = "data/clinical_follow_up_v2.1_brca.csv", row.names = FALSE)
write.csv(clinical_patient_brca, file = "data/clinical_patient_brca.csv", row.names = FALSE)
write.csv(clinical_omf_v4.0_brca, file = "data/clinical_omf_v4.0_brca.csv", row.names = FALSE)




##### NOTES #####

# Testing out queries
# query <- GDCquery(
#   project = "TCGA-BRCA", 
#   data.category = "Clinical",
#   data.type = "Clinical Supplement", 
#   data.format = "BCR Biotab"
# )
# 
# GDCdownload(query)
# clinical_BCRtab_all <- GDCprepare(query)
# names(clinical.BCRtab.all)
# 
# # Extract per-patient clinical table
# idk <- clinical.BCRtab.all$clinical_drug_acc |>  
#   head() |> 
#   DT::datatable(options = list(scrollX = TRUE, keys = TRUE))
# 
# 
# idek <- dplyr::glimpse(clinical_BCRtab_all$clinical_patient_brca)
# ideek <- dplyr::glimpse(clinical_BCRtab_all$clinical_follow_up_v1.5_brca)
# 
# clinical <- GDCquery_clinic(
#   project = "TCGA-BRCA", 
#   type = "clinical"
# )
# 
# 
# clinical |> 
#   head() |> 
#   DT::datatable(
#     filter = 'top', 
#     options = list(scrollX = TRUE, keys = TRUE, pageLength = 5),  
#     rownames = FALSE
#   )
# 
# 
# clin_brca <- GDCquery_clinic("TCGA-BRCA", "clinical")
# TCGAanalyze_survival(
#   data = clin_brca,
#   clusterCol = "gender",
#   main = "TCGA Set\n BRCA",
#   height = 10,
#   width=10
# )
# 
# # WORKFLOW
# # 1. Query + download TCGA-BRCA clinical data.
# # Build a query for BRCA clinical data
# query_clinical <- GDCquery(
#   project       = "TCGA-BRCA",
#   data.category = "Clinical",
#   #data.format = "BCR Biotab",
#   data.type = "Clinical Supplement"
# )
# 
# # Download the clinical data (may take a minute)
# GDCdownload(query_clinical)
# 
# # 2. Extract/merge the clinical tables into one per‑patient dataset.
# # Per-patient table (baseline clinical info)
# clin_patient <- GDCprepare_clinic(query_clinical, clinical.info = "patient")
# 
# # Follow-up visits (additional survival info; optional but useful)
# clin_followup <- GDCprepare_clinic(query_clinical, clinical.info = "follow_up")
# 
# # Treatment tables (you can use these later to define regimens)
# clin_drug      <- GDCprepare_clinic(query_clinical, clinical.info = "drug")
# clin_radiation <- GDCprepare_clinic(query_clinical, clinical.info = "radiation")
# 
# 
# # 3. Derive time and status + covariates you care about.
# 
# # 3.1 Start with basic survival from patient data
# library(dplyr)
# 
# brca_surv <- clin_patient |> 
#   transmute(
#     patient_id = bcr_patient_barcode,
#     vital_status = vital_status,               # "Alive" / "Dead"
#     days_to_death = as.numeric(days_to_death),
#     days_to_last_followup = as.numeric(days_to_last_followup),
#     # Survival time: if dead, use days_to_death; otherwise, last followup
#     time = case_when(
#       !is.na(days_to_death) ~ days_to_death,
#       !is.na(days_to_last_followup) ~ days_to_last_followup,
#       TRUE ~ NA_real_
#     ),
#     status = ifelse(vital_status == "Dead", 1, 0)
#   ) |> 
#   filter(!is.na(time))  # keep only patients with defined follow-up time
# 
# # 3.2 Add clinical covariates
# names(clin_patient)[grep("stage|ajcc|age|race|gender|ethnicity", names(clin_patient), ignore.case = TRUE)]
# 
# # Join other fields
# brca_surv_2 <- brca_surv %>%
#   left_join(
#     clin_patient %>%
#       transmute(
#         patient_id = bcr_patient_barcode,
#         stage_raw  = ajcc_pathologic_tumor_stage,
#         age        = as.numeric(age_at_initial_pathologic_diagnosis),
#         gender     = as.factor(gender),
#         race_raw   = race,              # or another similar field
#         ethnicity  = ethnicity
#       ),
#     by = "patient_id"
#   ) %>%
#   mutate(
#     # Simplify stage to I/II/III/IV
#     stage = case_when(
#       grepl("I",   stage_raw, ignore.case = TRUE) & !grepl("IV", stage_raw, ignore.case = TRUE) ~ "I",
#       grepl("II",  stage_raw, ignore.case = TRUE) & !grepl("III|IV", stage_raw, ignore.case = TRUE) ~ "II",
#       grepl("III", stage_raw, ignore.case = TRUE) ~ "III",
#       grepl("IV",  stage_raw, ignore.case = TRUE) ~ "IV",
#       TRUE ~ NA_character_
#     ),
#     age_group = cut(
#       age,
#       breaks = c(-Inf, 50, 65, Inf),
#       labels = c("<50", "50–65", ">65")
#     ),
#     race = forcats::fct_lump_n(as.factor(race_raw), n = 4)  # group rare categories
#   )
# 
# 
# # 3.3 Add simple treatment variables
# # Look at columns in clin_drug
# names(clin_drug)
# head(clin_drug[, c("bcr_patient_barcode", "pharmaceutical_therapy_type", "drug_name")])
# 
# # Create a per-patient flag for 'any chemo'
# chemo_patients <- clin_drug %>%
#   mutate(
#     is_chemo = grepl("CHEMO|CHEMOTHERAPY", pharmaceutical_therapy_type, ignore.case = TRUE) |
#       grepl("chemo", drug_name, ignore.case = TRUE)
#   ) %>%
#   group_by(bcr_patient_barcode) %>%
#   summarise(received_chemo = any(is_chemo, na.rm = TRUE), .groups = "drop")
# 
# # Similarly for radiation
# radiation_patients <- clin_radiation %>%
#   mutate(
#     received_radiation = TRUE
#   ) %>%
#   distinct(bcr_patient_barcode, received_radiation)
# 
# # Join into brca_surv and create a combined 'treatment_regimen'
# brca_surv_3 <- brca_surv_2 %>%
#   left_join(chemo_patients,    by = c("patient_id" = "bcr_patient_barcode")) %>%
#   left_join(radiation_patients, by = c("patient_id" = "bcr_patient_barcode")) %>%
#   mutate(
#     received_chemo     = ifelse(is.na(received_chemo), FALSE, received_chemo),
#     received_radiation = ifelse(is.na(received_radiation), FALSE, received_radiation),
#     treatment_regimen = case_when(
#       !received_chemo & !received_radiation ~ "No chemo / no radiation",
#       received_chemo & !received_radiation  ~ "Chemo only",
#       !received_chemo & received_radiation  ~ "Radiation only",
#       received_chemo & received_radiation   ~ "Chemo + radiation"
#     )
#   )
# 
# # 4 Resulting dataset structure
# str(brca_surv)
# 
# str(brca_surv)



# OLD: output$survival_plot <- renderPlotly({
#   df <- filtered_data()
#   req(nrow(df) > 0)
#   
#   strat_var <- input$strata_var
#   
#   # If no stratification, just show a single histogram as before
#   if (is.null(strat_var) || strat_var == "none") {
#     return(
#       plot_ly(
#         data   = df,
#         x      = ~time,
#         type   = "histogram",
#         color  = ~vital_status,
#         nbinsx = 12,
#         opacity = 0.5,
#         source = "survival_plot"
#       ) |> 
#         layout(
#           barmode = "overlay",
#           xaxis = list(title = "Time to Event (Days)"),
#           yaxis = list(title = "# Cases")
#         )
#     )
#   }
#   
#   # Otherwise: one histogram per level of the chosen stratification variable
#   # Make sure the column exists and is not all NA
#   if (!strat_var %in% names(df)) return(NULL)
#   if (all(is.na(df[[strat_var]]))) return(NULL)
#   
#   # Split data by the stratification variable
#   split_list <- split(df, df[[strat_var]])
#   
#   # Build one histogram per group
#   plots <- lapply(names(split_list), function(g) {
#     d_sub <- split_list[[g]]
#     
#     plot_ly(
#       data   = d_sub,
#       x      = ~time,
#       type   = "histogram",
#       color  = ~vital_status,
#       nbinsx = 12,
#       opacity = 0.5,
#       showlegend = (g == names(split_list)[1])  # show legend only once
#     ) %>%
#       layout(
#         title  = paste(strat_var, "=", g),
#         barmode = "overlay",
#         xaxis = list(title = "Time to Event (Days)"),
#         yaxis = list(title = "# Cases")
#       )
#   })
#   
#   # Arrange the plots
#   subplot(
#     plots,
#     nrows   = length(plots),
#     shareX  = TRUE,
#     shareY  = TRUE,
#     titleY  = TRUE
#     
#   )
# })