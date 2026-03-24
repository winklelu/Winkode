# ============================================================
# KM Curve — Kaplan-Meier Overall Survival Plot
# Author  : Winkle Lu | WinSual (winklelu.github.io/WinSual)
# Version : 2.0
# Output  : PNG + RTF (via reporter package)
# ============================================================
#
# QUICK START
# -----------
# Step 1: Run as-is with built-in dummy data to preview the plot.
# Step 2: Replace the dummy data section with your own dataset.
#
# HOW TO USE YOUR OWN DATA
# -------------------------
# Your dataset needs these columns:
#
#   USUBJID  : Subject ID          (character)  e.g. "001-001"
#   TRTA     : Treatment arm label (character)  e.g. "Treatment A"
#   AVAL     : Time to event       (numeric)    unit: months
#   CNSR     : Censoring flag      (numeric)    1 = censored, 0 = event
#
# Replace the dummy data block (Section 1) with one of the following:
#
#   # --- Read CSV ---
#   # install.packages("readr")
#   library(readr)
#   adtte <- read_csv("your_adtte.csv")
#
#   # --- Read SAS dataset (.sas7bdat) ---
#   # install.packages("haven")
#   library(haven)
#   adtte <- read_sas("adtte.sas7bdat")
#
#   # --- Read Excel ---
#   # install.packages("readxl")
#   library(readxl)
#   adtte <- read_excel("adtte.xlsx")
#
#   # --- Read XPT (SAS transport) ---
#   # install.packages("haven")
#   library(haven)
#   adtte <- read_xpt("adtte.xpt")
#
# After loading your data, make sure column names match the
# variables used in Section 2 onwards. Rename if needed:
#   adtte <- adtte %>% rename(AVAL = your_time_col,
#                             CNSR = your_censor_col)
#
# OUTPUT FILES
# ------------
# This script produces two output files:
#   1. km_curve_OS.png  — high-resolution PNG (300 dpi)
#   2. km_curve_OS.rtf  — RTF report (via reporter package)
#
# To install reporter:
#   install.packages("reporter")
#
# ============================================================

# ============================================================
# 0. LOAD PACKAGES
# ============================================================
suppressPackageStartupMessages({
  library(survival)   # Surv(), survfit(), coxph()
  library(ggplot2)    # plotting
  library(dplyr)      # data manipulation
  library(tibble)     # tibble()
  library(scales)     # percent_format()
  library(grid)       # unit()
  library(gridExtra)  # arrangeGrob()
  library(reporter)   # RTF output: create_report(), write_report()
})

# ============================================================
# 1. DUMMY DATA — Replace this section with your own data
# ============================================================
set.seed(2026)

# Number of subjects per arm
N_PER_ARM <- 30

# Generate subject IDs in format: 001-001, 001-002, ...
subj_A <- sprintf("001-%03d", 1:N_PER_ARM)
subj_B <- sprintf("002-%03d", 1:N_PER_ARM)

# Simulate survival time (months) using Weibull distribution
# Treatment A: longer survival (median ~20 months)
# Treatment B: shorter survival (median ~12 months)
time_A <- round(rweibull(N_PER_ARM, shape = 1.4, scale = 22), 1)
time_B <- round(rweibull(N_PER_ARM, shape = 1.4, scale = 13), 1)

# Censoring: 1 = censored, 0 = event (e.g. death)
cnsr_A <- rbinom(N_PER_ARM, size = 1, prob = 0.35)
cnsr_B <- rbinom(N_PER_ARM, size = 1, prob = 0.25)

# Combine into one data frame (ADTTE structure)
adtte <- tibble(
  USUBJID = c(subj_A,        subj_B),
  TRTA    = c(rep("Treatment A", N_PER_ARM),
              rep("Treatment B", N_PER_ARM)),
  AVAL    = c(time_A,  time_B),   # Time to event (months)
  CNSR    = c(cnsr_A,  cnsr_B),   # 1 = censored, 0 = event
  PARAMCD = "OS",                  # Parameter code
  PARAM   = "Overall Survival"     # Parameter label
)

# ============================================================
# 2. SURVIVAL ANALYSIS
# ============================================================

# Create survival object
# CNSR = 1 means censored, so event = 1 - CNSR
surv_obj <- Surv(time  = adtte$AVAL,
                 event = 1 - adtte$CNSR)

# Kaplan-Meier fit by treatment arm
km_fit <- survfit(surv_obj ~ TRTA, data = adtte)

# Cox proportional hazards model for HR and CI
cox_fit <- coxph(surv_obj ~ TRTA, data = adtte)
cox_sum <- summary(cox_fit)

hr     <- round(cox_sum$conf.int[1, 1], 2)
hr_lo  <- round(cox_sum$conf.int[1, 3], 2)
hr_hi  <- round(cox_sum$conf.int[1, 4], 2)
pval   <- cox_sum$logtest["pvalue"]
pval_s <- ifelse(pval < 0.001,
                 "p < 0.001",
                 paste0("p = ", formatC(pval, digits = 3, format = "f")))

# Annotation label: HR + p-value (kept for reference)
hr_label <- paste0(
  "HR = ", hr, " (95% CI: ", hr_lo, "\u2013", hr_hi, ")\n", pval_s
)

# Extract median survival per arm with 95% CI
med_tbl <- summary(km_fit)$table

# X-axis upper limit: last observed time (event or censored) across all arms
last_obs_time <- max(adtte$AVAL)
x_max         <- ceiling(last_obs_time / 6) * 6
time_breaks   <- seq(0, x_max, by = 6)

# Arm names and sample size — derived from data, not hardcoded
arm_levels <- levels(factor(adtte$TRTA))
n_per_arm  <- table(adtte$TRTA)

# Build per-arm stats for inset annotation
arm_stats <- lapply(arm_levels, function(arm) {
  key    <- paste0("TRTA=", arm)
  n_tot  <- as.integer(n_per_arm[arm])
  n_evt  <- as.integer(med_tbl[key, "events"])
  pct    <- round(n_evt / n_tot * 100, 1)
  med    <- as.numeric(med_tbl[key, "median"])   # force numeric
  med_lo <- as.numeric(med_tbl[key, "0.95LCL"])  # force numeric
  med_hi <- as.numeric(med_tbl[key, "0.95UCL"])  # force numeric; NA if NE
  med_ci <- if (is.na(med_hi)) {
    paste0(round(med, 1), " (", round(med_lo, 1), ", NE)")
  } else {
    paste0(round(med, 1), " (", round(med_lo, 1), ", ", round(med_hi, 1), ")")
  }
  list(n     = n_tot,
       evt   = n_evt,
       pct   = pct,
       med   = round(med, 1),   # numeric — used for median line x position
       med_ci = med_ci)         # character — used for annotation text only
})
names(arm_stats) <- arm_levels

# Inset annotation text — mimics CSR table format
# Build each line separately then collapse with real newline
w <- 22   # left column width

line0 <- paste0(strrep(" ", w),
                paste(sprintf("%14s", arm_levels), collapse = ""))
line1 <- paste0(sprintf("%-*s", w, "N"),
                paste(sprintf("%14s", sapply(arm_stats, `[[`, "n")),
                      collapse = ""))
line2 <- paste0(sprintf("%-*s", w, "Events (%)"),
                paste(sprintf("%14s",
                              sapply(arm_stats,
                                     function(s) paste0(s$evt, " (", s$pct, ")"))),
                      collapse = ""))
line3 <- paste0(sprintf("%-*s", w, "Median, 95% CI"),
                paste(sprintf("%14s",
                              sapply(arm_stats, `[[`, "med_ci")),
                      collapse = ""))
line4 <- paste0(sprintf("%-*s", w, "Hazard Ratio, 95% CI"),
                sprintf("%14s",
                        paste0(hr, " (", hr_lo, "\u2013", hr_hi, ")")))
line5 <- paste0(sprintf("%-*s", w, "P-value"),
                sprintf("%14s",
                        formatC(as.numeric(pval), digits = 4, format = "f")))

# Collapse with real newline character
inset_text <- paste(line0, line1, line2, line3, line4, line5, sep = "\n")

# ============================================================
# 3. TIDY KM DATA FOR PLOTTING
# ============================================================

# Extract KM summary — events only (for the step curve)
km_sum <- summary(km_fit)

km_df <- tibble(
  time    = km_sum$time,
  surv    = km_sum$surv,
  n.risk  = km_sum$n.risk,
  n.event = km_sum$n.event,
  group   = sub("TRTA=", "", as.character(km_sum$strata))
)

# Add time = 0 starting point for each arm
t0_df <- tibble(
  time    = 0,
  surv    = 1,
  n.risk  = NA_real_,
  n.event = 0,
  group   = arm_levels   # dynamic — derived from data
)

km_df <- bind_rows(t0_df, km_df) %>%
  mutate(group = factor(group, levels = arm_levels))

# Extend each arm's curve to x_max so the step line reaches the axis end
# Without this, geom_step stops at the last event time
extend_df <- km_df %>%
  filter(!is.na(n.risk)) %>%          # exclude t=0 placeholder
  group_by(group) %>%
  slice_tail(n = 1) %>%               # last row per group
  ungroup() %>%
  mutate(time    = x_max,             # extend to x-axis end
         n.risk  = NA_real_,
         n.event = NA_real_)

km_df <- bind_rows(km_df, extend_df) %>%
  arrange(group, time)

# Censoring tick marks: use censored = TRUE to capture censored-only timepoints
# These are rows where n.event == 0 (i.e. the subject was censored, not an event)
km_sum_all <- summary(km_fit, censored = TRUE)

# Find last event time per group — only show "+" within the curve range
last_event_time <- tibble(
  time    = km_sum$time,
  n.event = km_sum$n.event,
  group   = sub("TRTA=", "", as.character(km_sum$strata))
) %>%
  filter(n.event > 0) %>%
  group_by(group) %>%
  summarise(max_event = max(time), .groups = "drop")

cens_df <- tibble(
  time    = km_sum_all$time,
  surv    = km_sum_all$surv,
  n.event = km_sum_all$n.event,
  group   = sub("TRTA=", "", as.character(km_sum_all$strata))
) %>%
  filter(n.event == 0, time > 0) %>%
  left_join(last_event_time, by = "group") %>%
  # Only show "+" within the curve (up to last event time per group)
  # AND within the x-axis limit
  filter(time <= max_event, time <= x_max) %>%
  select(-max_event) %>%
  mutate(group = factor(group, levels = arm_levels))

# ============================================================
# 4. RISK TABLE DATA
# ============================================================

# arm_levels and n_per_arm are defined in Section 2
# Calculate number at risk at each time point (time_breaks defined in Section 2)
risk_tbl <- expand.grid(
  time  = time_breaks,
  group = arm_levels,
  stringsAsFactors = FALSE
) %>%
  as_tibble() %>%
  rowwise() %>%
  mutate(n_risk = {
    g <- group
    t <- time
    # At time = 0: use actual sample size from data (not hardcoded)
    if (t == 0) {
      as.integer(n_per_arm[g])
    } else {
      # Find the last known n.risk at or before time t
      sub <- km_df %>%
        filter(group == g, time <= t, !is.na(n.risk))
      if (nrow(sub) == 0) as.integer(n_per_arm[g])
      else as.integer(tail(sub$n.risk, 1))
    }
  }) %>%
  ungroup() %>%
  mutate(
    group   = factor(group, levels = rev(arm_levels)),
    n_label = as.character(n_risk)
  )

# ============================================================
# 5. COLOUR AND STYLE SETTINGS
# ============================================================

# Colour palette — adjust to your preference
COL_A <- "#BC3C29"   # red   — first arm  (arm_levels[1])
COL_B <- "#0072B5"   # blue  — second arm (arm_levels[2])

# Dynamically named by actual arm labels from data
PAL <- setNames(c(COL_A, COL_B), arm_levels)
LTY <- setNames(c("solid", "dashed"), arm_levels)

# ============================================================
# 6. MAIN KM PLOT
# ============================================================

p_km <- ggplot(km_df,
               aes(x = time, y = surv,
                   color = group, linetype = group)) +
  
  # Step curve
  geom_step(linewidth = 0.75) +
  
  # Censoring tick marks — "+" symbol
  # Filter to x-axis range (0–48) to avoid stray points outside plot area
  # show.legend = TRUE adds "+" to the legend
  geom_point(data = cens_df %>% filter(time >= 0, time <= x_max),
             aes(x = time, y = surv, color = group),
             shape       = 3,     # "+" shape
             size        = 3.0,   # adjust size as needed
             stroke      = 1.0,   # line thickness of "+"
             show.legend = TRUE) +
  
  # Median survival dotted lines — use annotate() not geom_segment(aes())
  # Arm 1 horizontal
  annotate("segment",
           x = 0, xend = as.numeric(arm_stats[[arm_levels[1]]]$med),
           y = 0.5, yend = 0.5,
           color = COL_A, linetype = "dotted", linewidth = 0.4) +
  # Arm 1 vertical
  annotate("segment",
           x    = as.numeric(arm_stats[[arm_levels[1]]]$med),
           xend = as.numeric(arm_stats[[arm_levels[1]]]$med),
           y = 0, yend = 0.5,
           color = COL_A, linetype = "dotted", linewidth = 0.4) +
  # Arm 2 horizontal
  annotate("segment",
           x = 0, xend = as.numeric(arm_stats[[arm_levels[2]]]$med),
           y = 0.5, yend = 0.5,
           color = COL_B, linetype = "dotted", linewidth = 0.4) +
  # Arm 2 vertical
  annotate("segment",
           x    = as.numeric(arm_stats[[arm_levels[2]]]$med),
           xend = as.numeric(arm_stats[[arm_levels[2]]]$med),
           y = 0, yend = 0.5,
           color = COL_B, linetype = "dotted", linewidth = 0.4) +
  
  # Inset annotation table (top-right) — mimics CSR format
  # Use geom_label with a single-row data frame for stability
  geom_label(data = data.frame(
    x = x_max * 0.42,
    y = 0.98,
    label = inset_text),
    aes(x = x, y = y, label = label),
    hjust      = 0,
    vjust      = 1,
    size       = 2.6,
    fill       = "white",
    color      = "grey15",
    label.size = 0.3,
    label.r    = unit(0.05, "lines"),
    family     = "mono",
    inherit.aes = FALSE) +
  
  # Colour and linetype scales
  # override.aes: show both line + "+" symbol in legend key
  scale_color_manual(
    values = PAL,
    name   = "Treatment",
    guide  = guide_legend(
      override.aes = list(
        linetype = c("solid", "dashed"),  # line style per group
        shape    = 3,                     # "+" symbol in legend
        size     = 3
      )
    )
  ) +
  scale_linetype_manual(values = LTY,
                        name   = "Treatment",
                        guide  = "none") +   # suppress duplicate legend
  
  # Axes
  scale_x_continuous(limits  = c(0, x_max),
                     breaks  = time_breaks,
                     expand  = c(0.01, 0)) +
  scale_y_continuous(limits  = c(0, 1.02),
                     breaks  = seq(0, 1, 0.2),
                     labels  = function(x) x * 100,
                     expand  = c(0, 0)) +
  
  # Clip all geoms strictly to x-axis range
  coord_cartesian(xlim = c(0, x_max), clip = "on") +
  
  # Labels
  labs(title    = "Kaplan\u2013Meier Estimate of Overall Survival",
       subtitle  = "Dummy ADTTE data",   # update when using real data
       x        = "Time (Months)",
       y        = "Overall Survival Probability (%)") +
  
  # Theme
  theme_classic(base_size = 12, base_family = "serif") +
  theme(
    plot.title         = element_text(size = 13, face = "bold",
                                      hjust = 0,
                                      margin = margin(b = 3)),
    plot.subtitle      = element_text(size = 9, color = "grey50",
                                      hjust = 0,
                                      margin = margin(b = 10)),
    axis.title         = element_text(size = 11),
    axis.text          = element_text(size = 10, color = "black"),
    axis.line          = element_line(linewidth = 0.45),
    axis.ticks         = element_line(linewidth = 0.35),
    panel.grid.major.y = element_line(color = "grey92",
                                      linewidth = 0.3),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = c(0.18, 0.18),
    legend.background  = element_rect(fill  = "white",
                                      color = "grey80",
                                      linewidth = 0.3),
    legend.key.width   = unit(1.5, "cm"),
    legend.text        = element_text(size = 10),
    legend.title       = element_text(size = 10, face = "bold"),
    plot.margin        = margin(12, 16, 4, 10)
  )

# ============================================================
# 7. RISK TABLE
# ============================================================

p_risk <- ggplot(risk_tbl,
                 aes(x = time, y = group, label = n_label)) +
  
  # Risk numbers — coloured by arm
  geom_text(aes(color = group),
            size      = 3.2,
            family    = "serif",
            fontface  = "bold",
            show.legend = FALSE) +
  
  scale_color_manual(values = setNames(c(COL_A, COL_B), arm_levels)) +
  scale_x_continuous(limits = c(0, x_max),
                     breaks = time_breaks,
                     expand = c(0.01, 0)) +
  scale_y_discrete(expand = c(0.5, 0)) +
  
  coord_cartesian(xlim = c(0, x_max), clip = "on") +
  
  labs(title = "Number at Risk", x = NULL, y = NULL) +
  
  theme_classic(base_size = 10, base_family = "serif") +
  theme(
    plot.title   = element_text(size = 9.5, face = "bold",
                                hjust = 0,
                                margin = margin(b = 2)),
    axis.text.y  = element_text(size = 9.5, face = "bold",
                                hjust = 1),
    axis.text.x  = element_blank(),
    axis.ticks   = element_blank(),
    axis.line    = element_blank(),
    panel.grid   = element_blank(),
    plot.margin  = margin(0, 16, 8, 10)
  )

# ============================================================
# 8. COMBINE AND EXPORT — PNG + RTF
# ============================================================

# --- 8a. Combine KM plot and risk table (3.2 : 1 height ratio) ---
km_final <- arrangeGrob(p_km, p_risk,
                        ncol    = 1,
                        heights = c(3.2, 1))

# --- 8b. Export PNG ---
# High-resolution PNG (300 dpi), suitable for publications
png_path <- "km_curve_OS.png"

png(filename = png_path,
    width    = 2800,
    height   = 2400,
    res      = 300,
    bg       = "white")

grid.draw(km_final)
dev.off()

cat("PNG saved to:", png_path, "\n")

# --- 8c. Export RTF via reporter ---
# reporter produces clinical-style RTF output
# compatible with Microsoft Word and SAS ODS RTF viewers
rtf_path <- "km_curve_OS.rtf"

# Create plot specification
# height + width in inches — sized to fit landscape page with header/footer
# Landscape page: 11 x 8.5 in; usable area ~9.5 x 6.5 in after margins
plt <- create_plot(png_path,
                   height = 6.0,   # inches — fits within landscape page
                   width  = 9.0)   # inches — adjust if needed

# Footnote: single string to avoid multi-row splitting
fn_text <- paste0(
  "HR = ", hr, " (95% CI: ", hr_lo, "\u2013", hr_hi, ");  ", pval_s, ";  ",
  "Median OS: Treatment A = ", med_A,
  " months  vs  Treatment B = ", med_B, " months"
)

# Build the RTF report
# orientation and paper_size belong in create_report()
# margins are set with set_margins()
rpt <- create_report(rtf_path,
                     output_type = "RTF",
                     orientation = "landscape",   # landscape page
                     paper_size  = "letter") %>%  # 11 x 8.5 in
  
  # Narrow margins to fit figure + header/footer on one page
  set_margins(top    = 0.5,
              bottom = 0.5,
              left   = 0.75,
              right  = 0.75) %>%
  
  # Page header (right-aligned)
  page_header(right = "WinViz Lab / WinSual") %>%
  
  # Figure titles (centred, bold)
  titles(
    "Figure: Kaplan-Meier Estimate of Overall Survival",
    "Intention-to-Treat Analysis Set",
    bold  = TRUE,
    align = "center"
  ) %>%
  
  # Embed the plot
  add_content(plt, align = "center") %>%
  
  # Footnote — single line to stay on same page as figure
  footnotes(fn_text, align = "left") %>%
  
  # Page footer (right-aligned)
  page_footer(right = "Program: km_curve_OS.R")

write_report(rpt)

cat("RTF saved to:", rtf_path, "\n")

# --- 8d. Console summary ---
cat("========================================\n")
cat(sprintf("Median OS  |  Treatment A: %.1f mo\n", med_A))
cat(sprintf("           |  Treatment B: %.1f mo\n", med_B))
cat(sprintf("HR = %.2f (95%% CI: %.2f\u2013%.2f)\n", hr, hr_lo, hr_hi))
cat(pval_s, "\n")
cat("========================================\n")