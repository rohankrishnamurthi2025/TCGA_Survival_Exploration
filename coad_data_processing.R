# Rohan Krishnamurthi Project: COAD data processing

# Install Packages
library(tidyverse)
library(shiny)
library(DT)
library(plotly)
library(bslib)
library(tidyverse)
library(survival)

getwd()

# Read in data
clinical_follow_up_v1.0_coad <- read.csv("data/clinical_follow_up_v1.0_coad.csv", header = TRUE)
clinical_radiation_coad <- read.csv("data/clinical_radiation_coad.csv", header = TRUE)
clinical_nte_coad <- read.csv("data/clinical_nte_coad.csv", header = TRUE)
clinical_omf_v4.0_coad <- read.csv("data/clinical_omf_v4.0_coad.csv", header = TRUE)
clinical_follow_up_v1.0_nte_coad <- read.csv("data/clinical_follow_up_v1.0_nte_coad.csv", header = TRUE)
clinical_patient_coad <- read.csv("data/clinical_patient_coad.csv", header = TRUE)
clinical_drug_coad <- read.csv("data/clinical_drug_coad.csv", header = TRUE)



# Selection of relevant datasets
# Primary: clinical_patient_brca
# Secondary: clinical_follow_up_v1.5_brca, clinical_follow_up_v2.1_brca, clinical_follow_up_v4.0_brca 
# Treatment covariates: clinical_drug_brca, clinical_radiation_brca
# Not relevant: clinical_nte_brca, clinical_follow_up_v4.0_nte_brca, clinical_omf_v4.0_brca

# Preprocess data
# Derive: time, status
# Extract: tumor stage age at diagnosis, sex, race, ethnicity 

patient_data <- clinical_patient_coad

# Fill in NA values
patient_data[patient_data == "[Not Applicable]"] <- NA
patient_data[patient_data == "[Not Available]"] <- NA
patient_data[patient_data == "[Not Evaluated]"] <- NA
patient_data[patient_data == "[Unknown]"] <- NA
patient_data[patient_data == "[Discrepancy]"] <- NA

# Create `status` and `time` variables
patient_data <- patient_data |> 
  mutate(status = NA, time = NA)

patient_data <- patient_data |> 
  filter(!is.na(vital_status))

for (i in seq_len(nrow(patient_data)) ){
  if (patient_data[i, "vital_status"] == "Dead"){
    patient_data[i, "status"] <- 1
    patient_data[i, "time"] <- as.integer(patient_data[i, "death_days_to"])
  } else if (patient_data[i, "vital_status"] == "Alive") {
    patient_data[i, "status"] <- 0
    patient_data[i, "time"] <- as.integer(patient_data[i, "last_contact_days_to"])
  }
}

patient_data <- patient_data |> 
  filter(!is.na(time)) 

patient_data |> 
  select("vital_status", "status", "time", "death_days_to", "last_contact_days_to") |> 
  head(n = 20)

# Select and modify covariates
patient_data <- patient_data |> 
  mutate(
    age_at_initial_pathologic_diagnosis = as.numeric(age_at_initial_pathologic_diagnosis),
    gender = factor(gender),
    race = factor(race),
    ethnicity = factor(ethnicity) # no menopause_status
  ) |> 
  rename(
    histological_type = histologic_diagnosis,
    age_at_diagnosis = age_at_initial_pathologic_diagnosis
  )


# Stage & tumor characteristics
# Simple pathologic stage I/II/III/IV from ajcc_pathologic_tumor_stage
patient_data <- patient_data |> mutate(
  stage = case_when(
    grepl("(?i)stage i[^v]",  ajcc_pathologic_tumor_stage) & !grepl("ii|iii|iv", ajcc_pathologic_tumor_stage, ignore.case = TRUE) ~ "I",
    grepl("(?i)stage ii",     ajcc_pathologic_tumor_stage) & !grepl("iii|iv",    ajcc_pathologic_tumor_stage, ignore.case = TRUE) ~ "II",
    grepl("(?i)stage iii",    ajcc_pathologic_tumor_stage) ~ "III",
    grepl("(?i)stage iv",     ajcc_pathologic_tumor_stage) ~ "IV",
    TRUE ~ NA_character_
  ),
  stage = factor(stage, levels = c("I", "II", "III", "IV"))
)

coad_patient_data_processed <- patient_data


# Treatment indicators

# Treatment variables: 
# radiation_treatment_adjuvant
# history_neoadjuvant_treatment
# pharmaceutical_tx_adjuvant
# surgical_procedure_first
# first_surgical_procedure_other

# Can integrate other data frames later


write.csv(coad_patient_data_processed, file = "data/coad_patient_data_processed.csv", row.names = FALSE)



