# data_dummy.R
# Simulated clinical data: AE, EX, CM, LB_CHEM, SU_SMOKE
# Purpose: Provide test data for Clinical Data Viewer
# To use real data, replace this file only — no changes needed in the main app

library(dplyr)

set.seed(123)

# Generate 10 USUBJIDs in format xxx-xxx
usubjid_list <- sprintf("%03d-%03d", rep(1:2, each = 5), 1:10)
n_per_subject <- 3
n_total       <- length(usubjid_list) * n_per_subject

# ── AE Data ──
data_ae <- data.frame(
  USUBJID  = rep(usubjid_list, each = n_per_subject),
  AESTDAT  = as.Date("2023-01-01") + sample(1:150, n_total, replace = TRUE),
  AEENDAT  = as.Date("2023-01-30") + sample(151:300, n_total, replace = TRUE),
  AESEV    = sample(c("Mild", "Moderate", "Severe"), n_total, replace = TRUE),
  AETOXGR  = sample(c("Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5"), n_total, replace = TRUE),
  AETERM   = sample(c("Headache", "Nausea", "Fatigue"), n_total, replace = TRUE)
)

# ── EX Data ──
ex_treatment_map <- data.frame(
  USUBJID = usubjid_list,
  EXTRT   = sample(c("Drug A", "Drug B", "Drug C"), length(usubjid_list), replace = TRUE),
  EXDOSE  = sample(c(50, 75, 100), length(usubjid_list), replace = TRUE),
  EXROUTE = sample(c("Oral", "IV", "SubQ"), length(usubjid_list), replace = TRUE)
)

data_ex <- data.frame(
  USUBJID = rep(usubjid_list, each = n_per_subject),
  EXSTDAT = as.Date("2023-01-05") + sample(1:150, n_total, replace = TRUE)
) |>
  left_join(ex_treatment_map, by = "USUBJID")

# ── CM Data ──
data_cm <- data.frame(
  USUBJID = rep(usubjid_list, each = n_per_subject),
  CMSTDAT = as.Date("2023-01-07") + sample(1:150, n_total, replace = TRUE),
  CMDOSE  = sample(c(10, 20, 15), n_total, replace = TRUE),
  CMROUTE = sample(c("IV", "Oral", "SubQ"), n_total, replace = TRUE),
  CMTRT   = sample(c("Med A", "Med B", "Med C"), n_total, replace = TRUE)
)

# ── LB_CHEM Data ──
data_lb <- data.frame(
  USUBJID  = rep(usubjid_list, each = n_per_subject),
  LBDAT    = as.Date("2023-01-10") + sample(1:150, n_total, replace = TRUE),
  LBTEST   = sample(c("ALT", "AST", "BUN"), n_total, replace = TRUE),
  LBSTRESN = round(runif(n_total, 10, 100), 1),
  LBSTRESU = "U/L"
)

# ── SU_SMOKE Data ──
data_su <- data.frame(
  USUBJID = rep(usubjid_list, each = n_per_subject),
  SUDAT   = as.Date("2023-01-12") + sample(1:150, n_total, replace = TRUE),
  SUTRT   = sample(c("Cigarette", "Cigar", "None"), n_total, replace = TRUE),
  SUFREQ  = sample(c("Daily", "Occasional", "Former"), n_total, replace = TRUE)
)

# ── Combined data list ──
form_data <- list(
  "AE"       = data_ae,
  "EX"       = data_ex,
  "CM"       = data_cm,
  "LB_CHEM"  = data_lb,
  "SU_SMOKE" = data_su
)

# ── CRF label mapping ──
form_labels <- list(
  "AE"       = "Adverse Events (AE)",
  "EX"       = "Exposure (EX)",
  "CM"       = "Concomitant Medications (CM)",
  "LB_CHEM"  = "Chemistry (LB_CHEM)",
  "SU_SMOKE" = "Tobacco Substance (SU_SMOKE)"
)

# ── Variable label mapping ──
var_labels <- lapply(form_data, names)

# ── All USUBJIDs across all domains ──
all_usubjid <- sort(unique(unlist(lapply(form_data, function(d) d$USUBJID))))
