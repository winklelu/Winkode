# ============================================================
# Swimming Plot — Duration on Treatment by Patient
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
# Your dataset needs these columns (one row per subject per visit):
#
#   USUBJID  : Subject ID              (character)  e.g. "001-001"
#   TRTA     : Treatment arm label     (character)  e.g. "Treatment A"
#   AVALC    : Tumor response at visit (character)  "CR","PR","SD","PD","NE"
#   ADY      : Study day of assessment (numeric)    e.g. 1, 43, 85
#   AENDY    : Last study day (end)    (numeric)    last observed day per subject
#   DISC     : Discontinued from study (logical)    TRUE / FALSE
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
#     filter(PARAMCD == "OVRLRESP", ANL01FL == "Y")
#
#   # --- Read XPT (SAS transport) ---
#   library(haven)
#   adrs <- read_xpt("adrs.xpt") %>%
#     filter(PARAMCD == "OVRLRESP", ANL01FL == "Y")
#
# After loading, rename columns if needed:
#   adrs <- adrs %>% rename(AVALC = your_response_col,
#                           ADY   = your_day_col,
#                           AENDY = your_end_day_col,
#                           DISC  = your_disc_flag)
#
# Y-AXIS ARM LABEL CUSTOMISATION
# --------------------------------
# Each subject's Y-axis label is formatted as:
#   "{arm_prefix} {USUBJID}"  e.g. "TRT-A 001-024"
#
# Define arm_prefix_map to map TRTA values to short labels:
#   arm_prefix_map <- c(
#     "Treatment A"  = "TRT-A",
#     "Treatment B"  = "TRT-B"
#   )
# This is defined in Section 3 — update to match your arm names.
#
# NOTE ON SORTING
# ---------------
# Y-axis is sorted by: Treatment arm → DURATION (desc) → USUBJID
# Longest bars appear at the top within each arm.
#
# NOTE ON REFERENCE GROUP
# -----------------------
# To control arm display order:
#   adrs <- adrs %>%
#     mutate(TRTA = relevel(factor(TRTA), ref = "Placebo"))
#
# OUTPUT FILES
# ------------
#   swimming_plot.png  — high-resolution PNG (300 dpi)
#   swimming_plot.rtf  — RTF report (via reporter package)
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
  library(tidyr)      # complete()
  library(reporter)   # RTF output: create_report(), write_report()
})

# ============================================================
# 1. DUMMY DATA — Replace this section with your own data
# ============================================================
set.seed(2026)

N_PER_ARM <- 15   # subjects per arm

subj_A <- sprintf("001-%03d", 1:N_PER_ARM)
subj_B <- sprintf("002-%03d", 1:N_PER_ARM)
all_subj <- c(subj_A, subj_B)
all_trta <- c(rep("Treatment A", N_PER_ARM),
              rep("Treatment B", N_PER_ARM))
N_TOTAL <- length(all_subj)

# Visit schedule: Baseline + every ~6 weeks
# ADY: Day 1 = Baseline, Day 43 = ~6w, Day 85 = ~12w, etc.
visit_days <- c(1, 43, 85, 127, 169, 211)

# Assign overall response trajectory per subject
# Treatment A: better response profile
# Treatment B: worse response profile
sim_responses <- function(trta) {
  r <- runif(1)
  if (trta == "Treatment A") {
    if      (r < 0.10) c("SD","PR","CR","CR","CR","CR")
    else if (r < 0.30) c("SD","PR","PR","PR","SD","SD")
    else if (r < 0.50) c("SD","SD","SD","PR","PR","PR")
    else if (r < 0.65) c("SD","SD","SD","PD","PD", NA)   # PD has next visit
    else if (r < 0.75) c("SD","NE","SD","PD","PD", NA)   # NE then PD
    else               c("SD","PD","PD", NA,  NA,  NA)   # early PD
  } else {
    if      (r < 0.08) c("SD","PR","PR","SD","SD","SD")
    else if (r < 0.20) c("SD","SD","PR","SD","PD","PD")  # late PD
    else if (r < 0.40) c("SD","SD","PD","PD", NA,  NA)   # PD has next visit
    else if (r < 0.60) c("SD","PD","PD", NA,  NA,  NA)   # early PD
    else if (r < 0.75) c("SD","NE","PD","PD", NA,  NA)   # NE then PD
    else               c("SD","SD","PD","PD", NA,  NA)
  }
}

# Build ADRS: one row per subject per visit
adrs_list <- lapply(seq_len(N_TOTAL), function(i) {
  subj <- all_subj[i]
  trta <- all_trta[i]
  resp <- sim_responses(trta)

  # Find last non-NA visit
  last_idx <- max(which(!is.na(resp)))

  # Discontinued = did not complete all visits
  disc <- last_idx < length(visit_days)

  # DISC_DAY: if discontinued, randomly place between last visit and next visit
  # This simulates subjects leaving study between two assessment time points
  if (disc && last_idx < length(visit_days)) {
    last_visit_day <- visit_days[last_idx]
    next_visit_day <- visit_days[last_idx + 1]
    # Random day between last visit + 7 days and next visit - 7 days
    disc_day <- round(runif(1,
                            last_visit_day + 7,
                            next_visit_day - 7))
  } else {
    disc_day <- visit_days[last_idx]   # completer: disc_day = last visit
  }

  data.frame(
    USUBJID  = subj,
    TRTA     = trta,
    ADY      = visit_days[seq_len(last_idx)],
    AVALC    = resp[seq_len(last_idx)],
    AENDY    = disc_day,   # last day on study (= disc_day or last visit)
    DISC     = disc,
    stringsAsFactors = FALSE
  )
})

adrs <- do.call(rbind, adrs_list)

# ============================================================
# 2. DATA PREPARATION
# ============================================================

# --- 2a. Treatment arm order ---
arm_levels <- levels(factor(adrs$TRTA))

# --- 2b. Subject-level summary ---
# One row per subject: TRTA, DURATION, DISC
subj_summary <- adrs %>%
  group_by(USUBJID, TRTA) %>%
  summarise(
    DURATION = max(AENDY),     # last study day = bar length
    DISC     = any(DISC),      # discontinued flag
    .groups  = "drop"
  ) %>%
  mutate(TRTA = factor(TRTA, levels = arm_levels))

# --- 2c. Sort order: arm → DURATION desc → USUBJID ---
# Treatment A first (all subjects), then Treatment B
# Within each arm: longest duration on top, then alphabetical USUBJID
subj_order <- subj_summary %>%
  arrange(TRTA,              # arm_levels order: A before B
          desc(DURATION),    # longest on top
          USUBJID) %>%       # alphabetical as tiebreaker
  pull(USUBJID)

# ============================================================
# 3. Y-AXIS ARM LABEL — User-defined prefix
# ============================================================

# Define short arm labels for Y-axis display
# Update these to match your actual TRTA values
# Add one entry per treatment arm — must cover all values in adrs$TRTA
# Example with 3 arms:
#   arm_prefix_map <- c(
#     "Placebo"     = "PBO",
#     "Dose 100mg"  = "D100",
#     "Dose 200mg"  = "D200"
#   )
arm_prefix_map <- c(
  "Treatment A" = "TRT-A",
  "Treatment B" = "TRT-B"
)

# Build Y-axis label: "{prefix} {USUBJID}"
subj_summary <- subj_summary %>%
  mutate(
    arm_prefix = arm_prefix_map[as.character(TRTA)],
    Y_LABEL    = paste(arm_prefix, USUBJID)
  )

# Y_LABEL factor levels — reversed so Treatment A is on top
# subj_order is Treatment A (long→short) then Treatment B (long→short)
# rev() makes ggplot display Treatment A at top of Y-axis
y_label_order <- subj_summary %>%
  arrange(match(USUBJID, subj_order)) %>%
  pull(Y_LABEL)

adrs <- adrs %>%
  left_join(subj_summary %>%
              select(USUBJID, DURATION, Y_LABEL),
            by = "USUBJID") %>%
  mutate(
    TRTA    = factor(TRTA,    levels = arm_levels),
    USUBJID = factor(USUBJID, levels = subj_order),
    # Y_LABEL levels follow subj_order directly
    # scale_y_discrete(limits = rev) handles display order
    Y_LABEL = factor(Y_LABEL, levels = y_label_order)
  )

# ============================================================
# 4. BUILD SEGMENT DATA
# ============================================================
# Each bar segment = one assessment interval
# Colour = tumor response (AVALC) at that visit
#
# XSTART = ADY of current visit
# XEND   = ADY of NEXT visit, BUT capped at AENDY (last study day)
#          This ensures discontinued subjects do NOT have segments
#          extending beyond their last observed day

seg_df <- adrs %>%
  arrange(USUBJID, ADY) %>%
  group_by(USUBJID) %>%
  mutate(
    XSTART   = ADY,
    next_ADY = lead(ADY),
    is_last  = is.na(next_ADY),
    # Non-last: segment ends at next visit
    # Last visit: segment ends at last visit day (NOT AENDY)
    # The gap from last visit to DISC_DAY is handled as a blank segment below
    XEND = case_when(
      !is_last ~ next_ADY,
      TRUE     ~ ADY        # last segment ends exactly at last visit
    )
  ) %>%
  ungroup() %>%
  filter(XSTART < XEND)   # remove zero-length segments

# Convert days to WEEKS for display (1 week = 7 days)
seg_df <- seg_df %>%
  mutate(
    XSTART_W = XSTART / 7,
    XEND_W   = XEND   / 7,
    AVALC_F  = factor(AVALC, levels = c("CR","PR","SD","PD","NE"))
  )

# Discontinued endpoint marker — at AENDY (= DISC_DAY, between visits)
# No blank segment drawn — the gap is simply left empty
disc_df <- adrs %>%
  group_by(USUBJID, Y_LABEL) %>%
  slice_max(order_by = ADY, n = 1) %>%
  ungroup() %>%
  filter(DISC) %>%
  mutate(XEND_W = AENDY / 7)   # X marker at DISC_DAY (between two visits)

# ============================================================
# 4b. OPTIONAL EVENT MARKERS
# ============================================================
# Add any clinical event as a point marker on the swimming bar.
# Each event needs its own data frame with columns:
#   USUBJID, Y_LABEL, EVENT_W (event day in weeks)
#
# Steps:
#   1. Uncomment the block for the event you want
#   2. Add the corresponding geom_point() in Section 6
#   3. Add a matching entry to the footnotes in Section 7
#
# The shape reference:
#   shape = 18  ◆ diamond  — recommended for response onset
#   shape = 15  ■ square   — recommended for progression
#   shape = 8   ✳ asterisk — recommended for death
#   shape = 17  ▲ triangle — recommended for other events

# --- Event 1: First CR or PR (Response Onset) ---
# event_response <- adrs %>%
#   filter(AVALC %in% c("CR", "PR")) %>%
#   group_by(USUBJID, Y_LABEL) %>%
#   slice_min(order_by = ADY, n = 1, with_ties = FALSE) %>%
#   ungroup() %>%
#   mutate(EVENT_W = ADY / 7)

# --- Event 2: First PD (Progression) ---
# event_pd <- adrs %>%
#   filter(AVALC == "PD") %>%
#   group_by(USUBJID, Y_LABEL) %>%
#   slice_min(order_by = ADY, n = 1, with_ties = FALSE) %>%
#   ungroup() %>%
#   mutate(EVENT_W = ADY / 7)

# --- Event 3: Custom event (e.g. Death, dose change) ---
# Requires an additional column in adrs (e.g. DEATH_DAY)
# event_death <- adrs %>%
#   filter(!is.na(DEATH_DAY)) %>%
#   distinct(USUBJID, Y_LABEL, DEATH_DAY) %>%
#   mutate(EVENT_W = DEATH_DAY / 7)

# ============================================================
# 5. COLOUR SETTINGS
# ============================================================

# Tumor response colours
RESP_COLS <- c(
  CR = "#1A7F37",   # green
  PR = "#2D9CDB",   # blue
  SD = "#F5A623",   # amber
  PD = "#D0021B",   # red
  NE = "#94A3B8"    # grey — not evaluable
)

# X-axis breaks: Baseline + every 6 weeks
# Include disc_df XEND_W to ensure X markers are not cut off
x_max_w    <- ceiling(max(c(seg_df$XEND_W, disc_df$XEND_W)) / 6) * 6
x_breaks_w <- c(0, seq(6, x_max_w, by = 6))
x_labels   <- c("Baseline", as.character(seq(6, x_max_w, by = 6)))

# ============================================================
# 6. SWIMMING PLOT
# ============================================================

p_swimming <- ggplot(seg_df,
  aes(y    = Y_LABEL,
      xmin = XSTART_W,
      xmax = XEND_W,
      fill = AVALC_F)) +

  # Blank segment: from last assessment to DISC_DAY — no colour, just empty
  # (handled by not drawing anything; only X marker shows the endpoint)

  # Colour segments — one per assessment interval (aligned to visit ticks)
  geom_tile(aes(x      = (XSTART_W + XEND_W) / 2,
                width  = XEND_W - XSTART_W,
                height = 0.7),
            color = "white", linewidth = 0.2) +

  # Discontinued marker: black ✕ at bar end
  geom_point(
    data        = disc_df,
    aes(x = XEND_W, y = Y_LABEL),
    shape       = 4,
    size        = 2.5,
    stroke      = 0.9,
    color       = "black",
    inherit.aes = FALSE
  ) +

  # ── OPTIONAL EVENT MARKERS ─────────────────────────────────
  # Uncomment and adapt each block after preparing the
  # corresponding data frame in Section 4b.

  # --- Event 1: First Response (CR or PR) — green diamond ◆ ---
  # geom_point(
  #   data        = event_response,
  #   aes(x = EVENT_W, y = Y_LABEL),
  #   shape       = 18,      # ◆ diamond
  #   size        = 3.0,
  #   color       = "#1A7F37",   # green — matches CR colour
  #   inherit.aes = FALSE
  # ) +

  # --- Event 2: First PD — red square ■ ---
  # geom_point(
  #   data        = event_pd,
  #   aes(x = EVENT_W, y = Y_LABEL),
  #   shape       = 15,      # ■ square
  #   size        = 2.5,
  #   color       = "#D0021B",   # red — matches PD colour
  #   inherit.aes = FALSE
  # ) +

  # --- Event 3: Death or custom event — black asterisk ✳ ---
  # geom_point(
  #   data        = event_death,
  #   aes(x = EVENT_W, y = Y_LABEL),
  #   shape       = 8,       # ✳ asterisk
  #   size        = 2.5,
  #   stroke      = 0.8,
  #   color       = "black",
  #   inherit.aes = FALSE
  # ) +
  # ───────────────────────────────────────────────────────────

  # 6-week reference line
  geom_vline(xintercept = 6,
             linetype   = "dotted",
             color      = "grey50",
             linewidth  = 0.4) +

  # Tumor response colour scale — force all levels to show in legend
  scale_fill_manual(
    values = RESP_COLS,
    name   = "Tumor Response",
    drop   = FALSE,
    guide  = guide_legend(
      override.aes = list(
        fill = unname(RESP_COLS[c("CR","PR","SD","PD","NE")])
      )
    )
  ) +

  # X-axis — weeks
  scale_x_continuous(
    breaks = x_breaks_w,
    labels = x_labels,
    expand = c(0.01, 0)
  ) +

  # Y-axis — arm prefix + USUBJID
  # limits = rev: Treatment A (longest first) on top, Treatment B below
  scale_y_discrete(limits = rev) +

  # Labels
  labs(
    title    = "Swimming Plot \u2014 Duration on Treatment by Patient",
    subtitle = "RECIST 1.1 \u2022 Dummy ADRS data \u2022 WinViz Lab / WinSual",
    x        = "Study Day (Week)",
    y        = NULL
  ) +

  # Theme
  theme_classic(base_size = 11, base_family = "serif") +
  theme(
    plot.title         = element_text(size = 12, face = "bold",
                                      hjust = 0,
                                      margin = margin(b = 3)),
    plot.subtitle      = element_text(size = 8.5, color = "grey50",
                                      hjust = 0,
                                      margin = margin(b = 10)),
    axis.title.x       = element_text(size = 10),
    axis.text.y        = element_text(size = 7.5, color = "black",
                                      hjust = 1),
    axis.text.x        = element_text(size = 9, color = "black"),
    axis.line          = element_line(linewidth = 0.4),
    axis.ticks         = element_line(linewidth = 0.3),
    panel.grid.major.x = element_line(color = "grey93",
                                      linewidth = 0.25),
    panel.grid.major.y = element_blank(),
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
# 7. EXPORT — PNG + RTF
# ============================================================

# --- 7a. PNG ---
png_path <- "swimming_plot.png"

# Height scales with number of subjects
n_subj   <- length(unique(adrs$USUBJID))
png_h    <- max(2000, n_subj * 80)

png(filename = png_path,
    width    = 3000,
    height   = png_h,
    res      = 300,
    bg       = "white")
print(p_swimming)
dev.off()

cat("PNG saved to:", png_path, "\n")

# --- 7b. RTF ---
# RTF plot height is calculated to fit on one landscape letter page
# Available height on landscape letter with 0.5" margins ≈ 6.5"
# Subtract title (~0.5") and footnotes (~0.5") → target plot height ≈ 5.5"
rtf_path <- "swimming_plot.rtf"

# Scale plot height in RTF by subject count, capped to fit one page
rtf_plot_h <- min(5.5, max(3.0, n_subj * 0.18))

plt <- create_plot(png_path,
                   height = rtf_plot_h,
                   width  = 9.0)

rpt <- create_report(rtf_path,
                     output_type = "RTF",
                     orientation = "landscape",
                     paper_size  = "letter") %>%
  set_margins(top    = 0.5, bottom = 0.5,
              left   = 0.75, right  = 0.75) %>%
  page_header(right = "WinViz Lab / WinSual") %>%
  titles(
    "Figure: Swimming Plot \u2014 Duration on Treatment by Patient",
    "RECIST 1.1 \u2022 Intention-to-Treat Analysis Set",
    bold = TRUE, align = "center"
  ) %>%
  add_content(plt, align = "center") %>%
  footnotes(
    "Bar colour indicates tumor response at each assessment interval.",
    "\u2715 Subject discontinued from study.",
    "CR = Complete Response; PR = Partial Response; SD = Stable Disease; PD = Progressive Disease; NE = Not Evaluable",
    # Uncomment the lines below when optional event markers are enabled:
    # "\u25c6 First CR or PR (Response Onset)",
    # "\u25a0 First Progressive Disease",
    # "* Death",
    align = "left"
  ) %>%
  page_footer(right = "Program: swimming_plot.R")

write_report(rpt)

cat("RTF saved to:", rtf_path, "\n")

# --- 7c. Console summary ---
cat("========================================\n")
cat("Swimming Plot — Data Summary\n")
cat("----------------------------------------\n")
cat("Total subjects  :", n_subj, "\n")
cat("Discontinued    :", sum(subj_summary$DISC), "\n")
adrs %>% distinct(USUBJID, TRTA) %>% count(TRTA) %>% print()
cat("========================================\n")
