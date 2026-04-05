# ============================================================
# Forest Plot — Subgroup Hazard Ratio Analysis
# Author  : Winkle Lu | WinSual (winklelu.github.io/WinSual)
# Version : 1.0
# Output  : PNG + RTF (via reporter package)
# ============================================================
#
# QUICK START
# -----------
# Step 1: Run as-is with built-in dummy data to preview the plot.
# Step 2: Replace the dummy data section with your own dataset.
# Step 3: Update forest_config.yaml to match your data columns and labels.
# Step 4: Run quarto render forest_report.qmd to generate the full report.
#
# HOW TO USE YOUR OWN DATA
# -------------------------
# Your dataset needs these columns (rename if needed):
#
#   USUBJID    : Subject ID            (character)  e.g. "001-001"
#   TRTA       : Treatment arm label   (character)  e.g. "Drug A"
#   CANCERTYPE : Cancer type           (character)  e.g. "HCC", "CRC", "NSCLC"
#   AGEGR1     : Age group             (character)  e.g. ">=65", "<65"
#   SEX        : Sex                   (character)  e.g. "Male", "Female"
#   RACE       : Race                  (character)  e.g. "Asian", "White"
#   ECOG       : ECOG performance      (character)  e.g. "0", "1"
#   AVAL       : Time to event         (numeric)    unit: days or months
#   CNSR       : Censoring flag        (integer)    0 = event, 1 = censored
#
# Replace the dummy data block (Section 2) with one of the following:
#
#   # --- Read CSV ---
#   library(readr)
#   adsl <- read_csv("your_adsl.csv")
#
#   # --- Read SAS dataset (.sas7bdat) ---
#   library(haven)
#   adsl <- read_sas("adsl.sas7bdat")
#
#   # --- Read Excel ---
#   library(readxl)
#   adsl <- read_excel("adsl.xlsx")
#
#   # --- Read XPT (SAS transport) ---
#   library(haven)
#   adsl <- read_xpt("adsl.xpt")
#
# After loading your data, rename columns if needed:
#   adsl <- adsl %>% rename(AVAL = your_time_col,
#                           CNSR = your_censor_col)
#
# YAML CONFIGURATION
# ------------------
# All plot parameters are controlled via forest_config.yaml:
#
#   report:         Protocol, figure number, data cutoff date
#   endpoint:       OS / PFS — change one line to update the full report
#   cancer_filter:  Filter by cancer type, or use "ALL" for all types
#   treatment:      Treatment and control arm labels (must match TRTA values)
#   subgroups:      Subgroup variables and levels (must match column names)
#   stats:          CI level, model type
#   plot:           x-axis range, colors, point size
#   text:           Footnotes
#   output:         PNG/RTF dimensions and DPI
#
# OUTPUT FILES
# ------------
# This script produces three output files:
#   1. forest_plot.png     — high-resolution PNG (300 dpi)
#   2. forest_plot.rtf     — RTF report (via reporter package)
#   3. forest_data.rds     — data object for forest_report.qmd
#
# To install required packages:
#   install.packages(c("tidyverse", "survival", "yaml", "reporter"))
#
# ============================================================

# ============================================================
# 0. LOAD PACKAGES
# ============================================================
suppressPackageStartupMessages({
  library(tidyverse)  # Data wrangling and ggplot2 visualization
  library(survival)   # Cox proportional hazards model: coxph(), Surv()
  library(yaml)       # Read YAML configuration file
  library(reporter)   # RTF output: create_report(), write_report()
})

# ============================================================
# 1. READ YAML CONFIGURATION
# ============================================================
# All parameters are controlled via forest_config.yaml.
# Do not hardcode values here — update the YAML instead.
config <- read_yaml("forest_config.yaml")

# ============================================================
# 2. DUMMY DATA — Replace this section with your own data
# ============================================================
set.seed(42)
n <- 300   # Total number of simulated subjects

adsl <- tibble(
  USUBJID    = sprintf("001-%03d", 1:n),
  
  # Treatment arm: alternating assignment (1:1 randomization)
  # Values must match treatment$trt_arm and treatment$ctrl_arm in YAML
  TRTA       = rep(c(config$treatment$trt_arm,
                     config$treatment$ctrl_arm), n/2),
  
  # Cancer type: randomly assigned with specified probabilities
  # Values must match cancer_filter$variable column in YAML
  CANCERTYPE = sample(c("HCC", "CRC", "NSCLC"),
                      n, replace = TRUE,
                      prob = c(0.4, 0.35, 0.25)),
  
  # Age group: dichotomized at age 65
  AGEGR1     = sample(c(">=65", "<65"),
                      n, replace = TRUE, prob = c(0.45, 0.55)),
  
  # Sex
  SEX        = sample(c("Male", "Female"),
                      n, replace = TRUE, prob = c(0.6, 0.4)),
  
  # Race
  RACE       = sample(c("Asian", "White"),
                      n, replace = TRUE, prob = c(0.65, 0.35)),
  
  # ECOG performance status
  ECOG       = sample(c("0", "1"),
                      n, replace = TRUE, prob = c(0.45, 0.55)),
  
  # Survival time (days): exponential distribution, rate = 0.03 → mean ~33 days
  AVAL       = rexp(n, rate = 0.03),
  
  # Censoring indicator: 0 = event (death), 1 = censored (alive / lost to follow-up)
  CNSR       = sample(c(0L, 1L),
                      n, replace = TRUE, prob = c(0.65, 0.35))
)

# ============================================================
# 3. CANCER TYPE FILTER
# ============================================================
# Controlled by cancer_filter$selected in YAML.
# Set to "ALL" to include all cancer types, or specify e.g. "HCC".
cancer_var      <- config$cancer_filter$variable
cancer_selected <- config$cancer_filter$selected

if (cancer_selected == "ALL") {
  adsl_sub <- adsl
} else {
  adsl_sub <- adsl %>%
    filter(.data[[cancer_var]] == cancer_selected)
}

# Subject counts for Dataset Summary table
n_total  <- nrow(adsl)
n_cancer <- nrow(adsl_sub)
n_trt    <- sum(adsl_sub$TRTA == config$treatment$trt_arm)
n_ctrl   <- sum(adsl_sub$TRTA == config$treatment$ctrl_arm)

cat(sprintf("Dataset: total=%d, %s=%d (trt=%d, ctrl=%d)\n",
            n_total, cancer_selected, n_cancer, n_trt, n_ctrl))

# ============================================================
# 4. HR / CI CALCULATION FUNCTION
# ============================================================
# Fits an unstratified Cox model for a single subgroup level.
# Returns HR, 95% CI, and Events/Subjects counts.
# Returns NULL if sample size < 5 or model fails to converge.
calc_hr <- function(data, subvar, subval, ref_arm, ci_level) {
  
  df <- data %>%
    filter(.data[[subvar]] == subval) %>%
    mutate(TRTA = relevel(factor(TRTA), ref = ref_arm))
  
  if (nrow(df) < 5) return(NULL)
  
  fit <- tryCatch(
    coxph(Surv(AVAL, CNSR == 0) ~ TRTA, data = df),
    error = function(e) NULL
  )
  if (is.null(fit)) return(NULL)
  
  # HR = exp(β); CI = exp(β ± z * SE)
  hr      <- exp(coef(fit)[1])
  ci_low  <- exp(confint(fit, level = ci_level)[1, 1])
  ci_high <- exp(confint(fit, level = ci_level)[1, 2])
  
  n_e_trt  <- sum(df$TRTA != ref_arm & df$CNSR == 0)  # Treatment events
  n_s_trt  <- sum(df$TRTA != ref_arm)                  # Treatment subjects
  n_e_ctrl <- sum(df$TRTA == ref_arm & df$CNSR == 0)   # Control events
  n_s_ctrl <- sum(df$TRTA == ref_arm)                   # Control subjects
  
  tibble(
    hr       = round(hr, 3),
    ci_low   = round(ci_low, 3),
    ci_high  = round(ci_high, 3),
    hr_label = sprintf("%.2f (%.3f, %.3f)", hr, ci_low, ci_high),
    trt_es   = sprintf("%d/%d", n_e_trt,  n_s_trt),
    ctrl_es  = sprintf("%d/%d", n_e_ctrl, n_s_ctrl)
  )
}

# ============================================================
# 5. BUILD FOREST PLOT DATA FRAME
# ============================================================
# Builds a row-by-row data frame with alternating header rows
# (group labels, no HR) and data rows (subgroup levels with HR).
# Structure mirrors the visual layout of the forest plot.
forest_rows <- list()

for (sg in config$subgroups) {
  
  # Header row: group label (e.g. "Age Years"), no numeric values
  forest_rows[[length(forest_rows) + 1]] <- tibble(
    label     = sg$group,
    is_header = TRUE,
    subgroup  = NA_character_,
    hr        = NA_real_,
    ci_low    = NA_real_,
    ci_high   = NA_real_,
    hr_label  = NA_character_,
    trt_es    = NA_character_,
    ctrl_es   = NA_character_
  )
  
  # Data rows: one row per subgroup level, with HR and CI
  for (lv in sg$levels) {
    res <- calc_hr(adsl_sub,
                   subvar   = sg$variable,
                   subval   = lv$value,
                   ref_arm  = config$treatment$ref_arm,
                   ci_level = config$stats$ci_level)
    
    forest_rows[[length(forest_rows) + 1]] <- tibble(
      label     = paste0("  ", lv$label),   # Two-space indent to distinguish from header
      is_header = FALSE,
      subgroup  = lv$value,
      hr        = if (!is.null(res)) res$hr       else NA_real_,
      ci_low    = if (!is.null(res)) res$ci_low   else NA_real_,
      ci_high   = if (!is.null(res)) res$ci_high  else NA_real_,
      hr_label  = if (!is.null(res)) res$hr_label else "NE",
      trt_es    = if (!is.null(res)) res$trt_es   else "—",
      ctrl_es   = if (!is.null(res)) res$ctrl_es  else "—"
    )
  }
}

# Bind all rows; y coordinate is reversed so the first row appears at the top
forest_df <- bind_rows(forest_rows) %>%
  mutate(
    row_id = row_number(),
    y      = max(row_number()) - row_number() + 1
  )

# ============================================================
# 6. DRAW FOREST PLOT
# ============================================================
x_lim    <- config$plot$x_limits
x_breaks <- config$plot$x_breaks
col_trt  <- config$plot$colors$trt
col_ctrl <- config$plot$colors$ctrl

# x positions for the three right-side annotation columns
# Adjust multipliers if columns overlap or are too spread out
x_trt_es   <- x_lim[2] * 1.15   # Treatment Events/Subjects column
x_ctrl_es  <- x_lim[2] * 1.50   # Control Events/Subjects column
x_hr_label <- x_lim[2] * 1.95   # HR (95% CI) column

p <- ggplot(forest_df, aes(y = y)) +
  
  # Vertical reference line at HR = 1 (null effect)
  geom_vline(xintercept = config$plot$null_line,
             linetype = "solid", color = "grey40", linewidth = 0.4) +
  
  # Horizontal segments: 95% CI for each subgroup level
  geom_segment(
    data = filter(forest_df, !is_header & !is.na(hr)),
    aes(x = ci_low, xend = ci_high, yend = y),
    color = col_trt, linewidth = 0.8
  ) +
  
  # Square point: HR point estimate (shape 15 = solid square)
  geom_point(
    data = filter(forest_df, !is_header & !is.na(hr)),
    aes(x = hr),
    shape = 15, size = config$plot$point_size, color = col_trt
  ) +
  
  # Left-side labels: bold for group headers, plain for subgroup levels
  geom_text(
    aes(x = x_lim[1] * 0.3, label = label,
        fontface = ifelse(is_header, "bold", "plain")),
    hjust = 0, size = 3.8, color = "grey10"
  ) +
  
  # Column headers (fixed at top of plot area)
  annotate("text", x = x_trt_es,   y = max(forest_df$y) + 1.2,
           label = sprintf("%s\nEvents/Subjects", config$treatment$trt_arm),
           hjust = 0.5, size = 3.2, fontface = "bold", color = "grey10") +
  annotate("text", x = x_ctrl_es,  y = max(forest_df$y) + 1.2,
           label = sprintf("%s\nEvents/Subjects", config$treatment$ctrl_arm),
           hjust = 0.5, size = 3.2, fontface = "bold", color = "grey10") +
  annotate("text", x = x_hr_label, y = max(forest_df$y) + 1.2,
           label = "non-stratified\nHazard Ratio (95% CI)",
           hjust = 0.5, size = 3.2, fontface = "bold", color = "grey10") +
  
  # Data values for each subgroup level
  geom_text(
    data = filter(forest_df, !is_header),
    aes(x = x_trt_es, label = trt_es),
    hjust = 0.5, size = 3.2, color = "grey10"
  ) +
  geom_text(
    data = filter(forest_df, !is_header),
    aes(x = x_ctrl_es, label = ctrl_es),
    hjust = 0.5, size = 3.2, color = "grey10"
  ) +
  geom_text(
    data = filter(forest_df, !is_header),
    aes(x = x_hr_label, label = hr_label),
    hjust = 0.5, size = 3.2, color = "grey10"
  ) +
  
  # x-axis: extend range to accommodate right-side annotation columns
  scale_x_continuous(
    breaks = x_breaks,
    limits = c(x_lim[1] * 0.3, x_hr_label * 1.2)
  ) +
  
  # y-axis: padding to prevent clipping of top header and bottom row
  scale_y_continuous(expand = expansion(add = c(0.5, 2))) +
  
  labs(
    title    = config$report$title,
    subtitle = sprintf("Dummy ADSL data \u2022 WinViz Lab / WinSual"),
    x        = sprintf("Hazard Ratio (%d%% CI)",
                       as.integer(config$stats$ci_level * 100)),
    caption  = paste0(
      "Data Cut-off: ", config$report$data_cutoff, " | ",
      "Data Extract: ", config$report$data_extract, "\n",
      config$text$footnote_method, "\n",
      config$text$footnote_data
    )
  ) +
  
  # Theme: hide all y-axis elements; retain x-axis and vertical gridlines
  theme_classic(base_size = 12) +
  theme(
    axis.text.y        = element_blank(),
    axis.ticks.y       = element_blank(),
    axis.title.y       = element_blank(),
    axis.line.y        = element_blank(),
    plot.title         = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle      = element_text(size = 10, hjust = 0.5, color = "grey30"),
    plot.caption       = element_text(size = 8,  hjust = 0,   color = "grey40"),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.3)
  )

# ============================================================
# 7. EXPORT PNG
# ============================================================
png_path <- "forest_plot.png"
png(png_path,
    width  = config$output$png_width,
    height = config$output$png_height,
    units  = "in",
    res    = config$output$png_dpi,
    bg     = "white")
print(p)
dev.off()
cat("PNG saved to:", png_path, "\n")

# ============================================================
# 8. EXPORT RTF
# ============================================================
# Title is embedded in the PNG; RTF omits titles() to keep figure on one page.
rtf_path <- "forest_plot.rtf"
rpt <- create_report(rtf_path,
                     output_type = "RTF",
                     orientation = "landscape",
                     paper_size  = "letter") %>%
  set_margins(top    = 0.3,
              bottom = 0.3,
              left   = 0.5,
              right  = 0.5) %>%
  page_header(left  = config$report$protocol,
              right = "FINAL") %>%
  add_content(
    create_plot(png_path,
                height = 5.8,
                width  = 9.5),
    align = "center"
  ) %>%
  footnotes(
    config$text$footnote_method,
    config$text$footnote_data,
    align = "left"
  ) %>%
  page_footer(
    left  = sprintf("Data Cut-off: %s", config$report$data_cutoff),
    right = "WinViz Lab / WinSual"
  )

write_report(rpt)
cat("RTF saved to:", rtf_path, "\n")

# ============================================================
# 9. SAVE DATA OBJECT FOR QUARTO REPORT
# ============================================================
# Packages all results into an RDS file for forest_report.qmd to consume.
# This ensures the Quarto report always reads the latest output
# without needing to re-run the analysis independently.
saveRDS(list(
  forest_df = forest_df,
  n_total   = n_total,
  n_cancer  = n_cancer,
  n_trt     = n_trt,
  n_ctrl    = n_ctrl,
  config    = config
), "forest_data.rds")
cat("RDS saved to: forest_data.rds\n")

# ============================================================
# Console summary
# ============================================================
cat("============================================\n")
cat(sprintf("Cancer filter : %s\n", cancer_selected))
cat(sprintf("Subjects      : %d (trt=%d, ctrl=%d)\n", n_cancer, n_trt, n_ctrl))
cat(sprintf("Subgroups     : %d\n",
            sum(!forest_df$is_header)))
cat("============================================\n")