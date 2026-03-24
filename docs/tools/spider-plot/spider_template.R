# ============================================================
# Spider Plot — Percentage Change from Baseline Over Time
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
#   USUBJID : Subject ID              (character)  e.g. "001-001"
#   TRTA    : Treatment arm label     (character)  e.g. "Treatment A"
#   ADY     : Study day of assessment (numeric)    e.g. 1, 42, 84
#   PCHG    : % change from baseline  (numeric)    e.g. -35.2
#
# One row per subject per visit — do NOT pre-aggregate.
# Spider plot requires all longitudinal time points.
#
# Replace Section 1 with one of the following:
#
#   # --- Read CSV ---
#   library(readr)
#   adtr <- read_csv("your_adtr.csv")
#
#   # --- Read SAS dataset (.sas7bdat) ---
#   library(haven)
#   adtr <- read_sas("adtr.sas7bdat") %>%
#     filter(PARAMCD == "LDIAM", ANL01FL == "Y")
#
#   # --- Read XPT (SAS transport) ---
#   library(haven)
#   adtr <- read_xpt("adtr.xpt") %>%
#     filter(PARAMCD == "LDIAM", ANL01FL == "Y")
#
# After loading, rename columns if needed:
#   adtr <- adtr %>% rename(ADY  = your_day_col,
#                           PCHG = your_pchg_col)
#
# NOTE ON REFERENCE GROUP
# -----------------------
# The first arm in arm_levels is plotted in COL_A (red).
# To change the reference group:
#   adtr <- adtr %>%
#     mutate(TRTA = relevel(factor(TRTA), ref = "Placebo"))
#
# NOTE ON VISIT LABELS
# --------------------
# By default this template maps ADY (study day) to visit labels.
# visit_labels is built dynamically from the data.
# To customise labels, edit the visit_labels vector in Section 2.
#
# OUTPUT FILES
# ------------
#   spider_plot.png  — high-resolution PNG (300 dpi)
#   spider_plot.rtf  — RTF report (via reporter package)
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

N_PER_ARM <- 30

subj_A <- sprintf("001-%03d", 1:N_PER_ARM)
subj_B <- sprintf("002-%03d", 1:N_PER_ARM)

# BOR assignment for trajectory simulation
assign_bor <- function(n, orr, cr_rate = 0.08) {
  sapply(runif(n), function(r) {
    if      (r < cr_rate)        "CR"
    else if (r < orr)            "PR"
    else if (r < orr + 0.35)     "SD"
    else                         "PD"
  })
}

bor_A   <- assign_bor(N_PER_ARM, orr = 0.50)
bor_B   <- assign_bor(N_PER_ARM, orr = 0.20)
bor_all <- c(bor_A, bor_B)

# Best % change per subject (used to simulate trajectory direction)
pchg_from_bor <- function(bor) {
  switch(bor,
    CR = runif(1, -100, -80),
    PR = runif(1,  -60, -30),
    SD = runif(1,  -29,  19),
    PD = runif(1,   20,  65)
  )
}

pchg_all <- round(sapply(bor_all, pchg_from_bor), 1)

# Visit schedule (study days): BL, 6w, 12w, 18w, 24w
visits <- c(0, 42, 84, 126, 168)

# Simulate longitudinal tumor trajectory toward best response
# Each subject has one PCHG value per visit
sim_traj <- function(bor, best_pchg) {
  n_v <- length(visits)
  pts <- switch(bor,
    CR = pmin(c(0, cumsum(rnorm(n_v-1, best_pchg/(n_v-1), 3))), 15),
    PR = pmin(c(0, cumsum(rnorm(n_v-1, best_pchg/(n_v-1), 5))), 20),
    SD = c(0, cumsum(rnorm(n_v-1, best_pchg/(n_v-1), 5))),
    PD = pmax(c(0, cumsum(rnorm(n_v-1, best_pchg/(n_v-1), 7))), -12)
  )
  data.frame(ADY = visits, PCHG = round(pts, 1))
}

# Build ADTR — one row per subject per visit
adtr_list <- mapply(function(subj, trta, bor, best) {
  traj <- sim_traj(bor, best)
  data.frame(USUBJID = subj, TRTA = trta, BOR = bor,
             ADY = traj$ADY, PCHG = traj$PCHG,
             stringsAsFactors = FALSE)
},
  c(subj_A, subj_B),
  c(rep("Treatment A", N_PER_ARM), rep("Treatment B", N_PER_ARM)),
  bor_all, pchg_all,
  SIMPLIFY = FALSE
)

adtr <- do.call(rbind, adtr_list)

# ============================================================
# 2. DATA PREPARATION
# ============================================================

# --- 2a. Treatment arm order ---
# Derived from data — no hardcoding
# To reorder: mutate(TRTA = relevel(factor(TRTA), ref = "Placebo"))
arm_levels <- levels(factor(adtr$TRTA))

# --- 2b. Apply factor to TRTA for consistent colour mapping ---
adtr <- adtr %>%
  mutate(TRTA = factor(TRTA, levels = arm_levels))

# --- 2c. USUBJID sorted by subject ID (alphabetical) ---
# Spider plot shows longitudinal trajectories — order by USUBJID,
# not by PCHG (unlike Waterfall)
subj_order <- sort(unique(adtr$USUBJID))
adtr <- adtr %>%
  mutate(USUBJID = factor(USUBJID, levels = subj_order))

# --- 2d. Visit labels — derived from data, not hardcoded ---
# Maps ADY (study day) to readable visit labels
# Modify this vector to match your study schedule
ady_unique    <- sort(unique(adtr$ADY))
visit_labels  <- setNames(
  c("Baseline", paste0(round(ady_unique[-1] / 7), "w")),
  as.character(ady_unique)
)

# --- 2e. Randomly assign discontinued subjects ---
# Some subjects discontinue at 12w (ADY=84) or 18w (ADY=126)
# Their trajectory is truncated at the discontinuation visit
# Adjust n_disc and disc_visits to match your study
set.seed(42)
all_subj    <- levels(adtr$USUBJID)
n_disc      <- round(length(all_subj) * 0.15)   # ~15% discontinued
disc_subj   <- sample(all_subj, n_disc)
disc_visits <- sample(c(84, 126), n_disc, replace = TRUE)   # ADY 12w or 18w

disc_df <- data.frame(
  USUBJID   = disc_subj,
  disc_ADY  = disc_visits,
  stringsAsFactors = FALSE
)

# Remove data points after discontinuation
adtr <- adtr %>%
  left_join(disc_df, by = "USUBJID") %>%
  filter(is.na(disc_ADY) | ADY <= disc_ADY) %>%
  mutate(DISCONTINUED = !is.na(disc_ADY))

# Discontinued endpoint markers — last observed point per discontinued subject
disc_end <- adtr %>%
  filter(DISCONTINUED) %>%
  group_by(USUBJID, TRTA) %>%
  slice_max(order_by = ADY, n = 1) %>%
  ungroup()

# Treatment arm colours — adjust to your preference
COL_A   <- "#BC3C29"   # red  — first arm  (arm_levels[1])
COL_B   <- "#0072B5"   # blue — second arm (arm_levels[2])

# Dynamically named by actual arm labels from data
PAL_TRT <- setNames(c(COL_A, COL_B), arm_levels)

# ============================================================
# 4. SPIDER PLOT
# ============================================================

p_spider <- ggplot(adtr,
  aes(x     = ADY,
      y     = PCHG,
      group = USUBJID,
      color = TRTA)) +

  # Individual patient lines — one line per subject
  geom_line(linewidth = 0.5, alpha = 0.7) +

  # Individual patient points at each visit
  geom_point(size = 1.3, alpha = 0.85) +

  # Discontinued marker: ✕ at last observed visit
  # Fixed black colour — consistent across all treatment arms
  geom_point(
    data        = disc_end,
    aes(x = ADY, y = PCHG, shape = "Discontinued"),
    color       = "black",
    size        = 3.5,
    stroke      = 1.0,
    inherit.aes = FALSE,
    show.legend = TRUE
  ) +
  # +20%: Progressive Disease threshold
  geom_hline(yintercept =  20,
             linetype = "dashed", color = "grey40",
             linewidth = 0.4) +
  # -30%: Partial Response threshold
  geom_hline(yintercept = -30,
             linetype = "dashed", color = "grey40",
             linewidth = 0.4) +
  # Zero baseline
  geom_hline(yintercept =   0,
             color = "black", linewidth = 0.35) +

  # Colour scale — Treatment legend colours match arm_levels order
  scale_color_manual(
    values = PAL_TRT,
    name   = "Treatment",
    guide  = guide_legend(
      override.aes = list(
        shape = 16,
        size  = 3,
        color = PAL_TRT[arm_levels]   # ordered by arm_levels, fully dynamic
      )
    )
  ) +

  # Shape scale — Discontinued legend shows black ✕
  scale_shape_manual(
    values = c("Discontinued" = 4),
    name   = NULL,
    guide  = guide_legend(
      override.aes = list(color = "black", size = 3.5, stroke = 1.0)
    )
  ) +

  # X-axis: study day → visit label (dynamic)
  scale_x_continuous(
    breaks = ady_unique,
    labels = visit_labels[as.character(ady_unique)]
  ) +

  # Y-axis — plain numbers, no % symbol
  scale_y_continuous(
    labels = function(x) as.character(x)
  ) +

  # Labels
  labs(
    title    = "Spider Plot \u2014 Percentage Change from Baseline Over Time",
    subtitle = "RECIST 1.1 \u2022 Dummy ADTR data \u2022 WinViz Lab / WinSual",
    x        = "Study Visit",
    y        = "Change from Baseline (%)"
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
    axis.text          = element_text(size = 9, color = "black"),
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
png_path <- "spider_plot.png"

png(filename = png_path,
    width    = 3000,
    height   = 1800,
    res      = 300,
    bg       = "white")
print(p_spider)
dev.off()

cat("PNG saved to:", png_path, "\n")

# --- 5b. RTF ---
rtf_path <- "spider_plot.rtf"

plt <- create_plot(png_path,
                   height = 5.5,
                   width  = 9.0)

rpt <- create_report(rtf_path,
                     output_type = "RTF",
                     orientation = "landscape",
                     paper_size  = "letter") %>%
  set_margins(top    = 0.5, bottom = 0.5,
              left   = 0.75, right  = 0.75) %>%
  page_header(right = "WinViz Lab / WinSual") %>%
  titles(
    "Figure: Spider Plot \u2014 Percentage Change from Baseline Over Time",
    "RECIST 1.1 \u2022 Intention-to-Treat Analysis Set",
    bold = TRUE, align = "center"
  ) %>%
  add_content(plt, align = "center") %>%
  footnotes(
    "Each line represents one patient.",
    "RECIST 1.1 thresholds: PR \u2264 \u221230%; PD \u2265 +20%",
    align = "left"
  ) %>%
  page_footer(right = "Program: spider_plot.R")

write_report(rpt)

cat("RTF saved to:", rtf_path, "\n")

# --- 5c. Console summary ---
cat("========================================\n")
cat("Spider Plot — Data Summary\n")
cat("----------------------------------------\n")
cat("Total subjects  :", length(unique(adtr$USUBJID)), "\n")
cat("Visits (ADY)    :", paste(ady_unique, collapse = ", "), "\n")
cat("Visit labels    :", paste(visit_labels, collapse = ", "), "\n")
cat("========================================\n")
