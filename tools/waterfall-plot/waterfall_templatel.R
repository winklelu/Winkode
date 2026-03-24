# ============================================================
# Waterfall Plot — Best Percentage Change from Baseline
# Author  : Winkle Lu | WinSual (winklelu.github.io/WinSual)
# Version : 2.0
# Output  : PNG + RTF (via reporter package)
# ============================================================
#
# QUICK START
# -----------
# Step 1: Run as-is with built-in dummy data to preview the plot.
# Step 2: Replace Section 1 with your own dataset.
#
# HOW TO USE YOUR OWN DATA
# -------------------------
# Your dataset needs these columns:
#
#   USUBJID   : Subject ID            (character)  e.g. "001-001"
#   TRTA      : Treatment arm label   (character)  e.g. "Treatment A"
#   PCHG      : % change from BL      (numeric)    e.g. -45.2
#               (can be multiple rows per subject)
#   BOR       : Best Overall Response (character)  "CR","PR","SD","PD"
#
# Replace Section 1 with one of the following:
#
#   # --- Read CSV ---
#   library(readr)
#   adrs <- read_csv("your_adrs.csv")
#
#   # --- Read SAS dataset (.sas7bdat) ---
#   library(haven)
#   adrs <- read_sas("adrs.sas7bdat") %>%
#     filter(PARAMCD == "PCHG", ANL01FL == "Y")
#
#   # --- Read XPT (SAS transport) ---
#   library(haven)
#   adrs <- read_xpt("adrs.xpt") %>%
#     filter(PARAMCD == "PCHG", ANL01FL == "Y")
#
# After loading, rename columns if needed:
#   adrs <- adrs %>% rename(PCHG = your_pchg_col,
#                           BOR  = your_bor_col)
#
# NOTE ON BOR VALUES
# ------------------
# BOR must be one of: "CR", "PR", "SD", "PD"
# If your data uses different labels (e.g. "Complete Response"),
# recode before plotting:
#   adrs <- adrs %>%
#     mutate(BOR = case_when(
#       AVALC == "CR" ~ "CR",
#       AVALC == "PR" ~ "PR",
#       AVALC == "SD" ~ "SD",
#       TRUE          ~ "PD"
#     ))
#
# NOTE ON REFERENCE GROUP
# -----------------------
# The first arm in arm_levels (Section 3) is plotted in COL_A (red).
# To change the reference group order:
#   adrs <- adrs %>%
#     mutate(TRTA = relevel(factor(TRTA), ref = "Placebo"))
#
# OUTPUT FILES
# ------------
#   waterfall_plot.png  — high-resolution PNG (300 dpi)
#   waterfall_plot.rtf  — RTF report (via reporter package)
#
# To install reporter:
#   install.packages("reporter")
#
# ============================================================

# ============================================================
# 0. LOAD PACKAGES
# ============================================================
suppressPackageStartupMessages({
  library(ggplot2)    # plotting
  library(dplyr)      # data manipulation
  library(tibble)     # tibble()
  library(reporter)   # RTF output: create_report(), write_report()
})

# ============================================================
# 1. DUMMY DATA — Replace this section with your own data
# ============================================================
set.seed(2026)

# Number of subjects per arm
N_PER_ARM <- 30

# Subject IDs in format: site-subject e.g. "001-001"
subj_A <- sprintf("001-%03d", 1:N_PER_ARM)
subj_B <- sprintf("002-%03d", 1:N_PER_ARM)

# Assign Best Overall Response (BOR)
# Treatment A: ~50% ORR (CR + PR)
# Treatment B: ~20% ORR
assign_bor <- function(n, orr, cr_rate = 0.08) {
  sapply(runif(n), function(r) {
    if      (r < cr_rate)        "CR"
    else if (r < orr)            "PR"
    else if (r < orr + 0.35)     "SD"
    else                         "PD"
  })
}

bor_A <- assign_bor(N_PER_ARM, orr = 0.50)
bor_B <- assign_bor(N_PER_ARM, orr = 0.20)
bor_all <- c(bor_A, bor_B)

# Simulate multiple % change visits per subject
# In real data, each subject may have multiple PCHG rows
pchg_from_bor <- function(bor) {
  switch(bor,
    CR = runif(1, -100, -80),
    PR = runif(1,  -60, -30),
    SD = runif(1,  -29,  19),
    PD = runif(1,   20,  65)
  )
}

# Build ADRS with one row per subject (dummy data simplified)
# Real data may have multiple rows per subject (multiple visits)
adrs <- tibble(
  USUBJID = c(subj_A,        subj_B),
  TRTA    = c(rep("Treatment A", N_PER_ARM),
              rep("Treatment B", N_PER_ARM)),
  BOR     = bor_all,
  PCHG    = round(sapply(bor_all, pchg_from_bor), 1)
)

# ============================================================
# 2. DATA PREPARATION
# ============================================================

# --- 2a. Select best (lowest) PCHG per subject ---
# If your ADRS has multiple visits per subject (multiple PCHG rows),
# this step selects the best (lowest) value for each subject.
# If your data already has one row per subject, this step is harmless.
adrs <- adrs %>%
  group_by(USUBJID, TRTA, BOR) %>%
  slice_min(order_by = PCHG, n = 1, with_ties = FALSE) %>%
  ungroup()

# --- 2b. Define treatment arm order ---
# Arm order determines colour assignment (COL_A = first, COL_B = second)
# To change order: mutate(TRTA = relevel(factor(TRTA), ref = "Placebo"))
arm_levels <- levels(factor(adrs$TRTA))   # alphabetical by default

# --- 2c. Sort and factor for waterfall shape ---
# All subjects sorted by PCHG ascending (worst PD on left, best CR on right)
wf_df <- adrs %>%
  arrange(PCHG) %>%
  mutate(
    USUBJID = factor(USUBJID, levels = USUBJID),   # fix x-axis order
    TRTA    = factor(TRTA,    levels = arm_levels)  # consistent colour mapping
  )

# ============================================================
# 3. COLOUR SETTINGS
# ============================================================

# Treatment arm colours — adjust to your preference
COL_A    <- "#BC3C29"   # red  — first arm  (arm_levels[1])
COL_B    <- "#0072B5"   # blue — second arm (arm_levels[2])

# Dynamically named by actual arm labels from data
ARM_COLS <- setNames(c(COL_A, COL_B), arm_levels)

# ============================================================
# 4. WATERFALL PLOT
# ============================================================

p_waterfall <- ggplot(wf_df,
  aes(x = USUBJID, y = PCHG, fill = TRTA)) +

  # Bars — one per subject, coloured by treatment arm
  geom_col(width = 0.8, color = "white", linewidth = 0.15) +

  # BOR label at top of each bar
  # Positive bars: label above bar (vjust < 0)
  # Negative bars: label below bar end (vjust > 1)
  geom_text(
    aes(label = BOR,
        vjust = ifelse(PCHG >= 0, -0.4, 1.3)),
    size     = 2.0,
    family   = "serif",
    color    = "grey20",
    fontface = "bold"
  ) +

  # RECIST 1.1 reference lines
  # +20%: Progressive Disease threshold
  geom_hline(yintercept =  20,
             linetype = "dotted", color = "grey40",
             linewidth = 0.4) +
  # -30%: Partial Response threshold
  geom_hline(yintercept = -30,
             linetype = "dotted", color = "grey40",
             linewidth = 0.4) +
  # Zero baseline
  geom_hline(yintercept =   0,
             color = "black", linewidth = 0.35) +

  # Colour scale — named dynamically from arm_levels
  scale_fill_manual(
    values = ARM_COLS,
    name   = "Treatment"
  ) +

  # Y-axis — plain numbers, no % symbol
  # % indicated in axis title instead
  scale_y_continuous(
    limits = c(-105, 80),
    breaks = seq(-100, 60, 20),
    labels = function(x) as.character(x)
  ) +

  # X-axis — USUBJID labels, rotated 90°
  scale_x_discrete() +

  # Labels
  labs(
    title    = "Waterfall Plot \u2014 Best Percentage Change from Baseline",
    subtitle = "RECIST 1.1 \u2022 Dummy ADRS data \u2022 WinViz Lab / WinSual",
    x        = "Subject ID",
    y        = "Best Change from Baseline (%)"
  ) +

  # Theme — publication-ready
  theme_classic(base_size = 11, base_family = "serif") +
  theme(
    plot.title         = element_text(size = 12, face = "bold",
                                      hjust = 0,
                                      margin = margin(b = 3)),
    plot.subtitle      = element_text(size = 8.5, color = "grey50",
                                      hjust = 0,
                                      margin = margin(b = 10)),
    axis.title         = element_text(size = 10),
    axis.text.y        = element_text(size = 9, color = "black"),
    axis.text.x        = element_text(size = 6.5, color = "black",
                                      angle = 90,
                                      hjust = 1, vjust = 0.5),
    axis.line          = element_line(linewidth = 0.4),
    axis.ticks         = element_line(linewidth = 0.3),
    panel.grid.major.y = element_line(color = "grey93",
                                      linewidth = 0.25),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "right",
    legend.background  = element_rect(fill  = "white",
                                      color = "grey80",
                                      linewidth = 0.25),
    legend.text        = element_text(size = 9),
    legend.title       = element_text(size = 9, face = "bold"),
    plot.margin        = margin(12, 16, 8, 10)
  )

# ============================================================
# 5. EXPORT — PNG + RTF
# ============================================================

# --- 5a. PNG ---
# Width scaled to number of subjects for readability
# Adjust width if subject count is very large or small
png_path <- "waterfall_plot.png"

png(filename = png_path,
    width    = max(2400, nrow(wf_df) * 40),   # dynamic width by N
    height   = 1800,
    res      = 300,
    bg       = "white")
print(p_waterfall)
dev.off()

cat("PNG saved to:", png_path, "\n")

# --- 5b. RTF ---
rtf_path <- "waterfall_plot.rtf"

plt <- create_plot(png_path,
                   height = 5.5,
                   width  = 9.0)

rpt <- create_report(rtf_path,
                     output_type = "RTF",
                     orientation = "landscape",
                     paper_size  = "letter") %>%
  set_margins(top    = 0.5, bottom = 0.5,
              left   = 0.75, right = 0.75) %>%
  page_header(right = "WinViz Lab / WinSual") %>%
  titles(
    "Figure: Waterfall Plot \u2014 Best Percentage Change from Baseline",
    "RECIST 1.1 \u2022 Intention-to-Treat Analysis Set",
    bold = TRUE, align = "center"
  ) %>%
  add_content(plt, align = "center") %>%
  footnotes(
    "RECIST 1.1 thresholds: PR \u2264 \u221230%; PD \u2265 +20%",
    "Bar colour indicates treatment arm.  Label on bar indicates Best Overall Response (BOR).",
    align = "left"
  ) %>%
  page_footer(right = "Program: waterfall_plot.R")

write_report(rpt)

cat("RTF saved to:", rtf_path, "\n")

# --- 5c. Console summary ---
cat("========================================\n")
cat("Waterfall Plot — Data Summary\n")
cat("----------------------------------------\n")
cat("Total subjects:", nrow(wf_df), "\n")
wf_df %>% count(TRTA, BOR) %>% print()
cat("========================================\n")
