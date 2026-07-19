# ============================================================
# Patient Timeline — Multi-Domain Event View
# Author  : Winkle Lu | WinSual (winklelu.github.io/WinSual)
# Version : 1.0
# Output  : PNG + Interactive HTML (via plotly)
# ============================================================
#
# QUICK START
# -----------
# Step 1: Run as-is with built-in dummy data to preview the plot.
# Step 2: Replace Section 1 with your own datasets.
#
# CORE IDEA
# ---------
#   1. Each source dataset (AE, EX, CM, LB, ...) has its own structure
#      and its own "anchor" date variable (AESTDAT, EXSTDAT, CMSTDAT, ...).
#   2. STANDARDIZE every dataset into one common format:
#        USUBJID | Time (Date) | Form (label) | tooltip (text)
#   3. STACK the standardized datasets with bind_rows().
#   4. PLOT everything on one shared time axis, faceted by subject:
#        x = Time, y = Form, color = Form, facet = USUBJID
#
# HOW TO USE YOUR OWN DATA
# -------------------------
# Any SDTM/raw domain can be added as long as it has:
#   USUBJID   : Subject ID              (character)  e.g. "001-001"
#   <anchor>  : an event date variable  (Date)        e.g. AESTDAT
#   <display> : any columns you want shown in the tooltip
#
# Replace Section 1 with one of the following:
#
#   # --- Read CSV ---
#   library(readr)
#   data_ae <- read_csv("your_ae.csv")
#
#   # --- Read SAS dataset (.sas7bdat) ---
#   library(haven)
#   data_ae <- read_sas("ae.sas7bdat")
#
#   # --- Read XPT (SAS transport) ---
#   library(haven)
#   data_ae <- read_xpt("ae.xpt")
#
# Then register each domain in Section 3 via prepare_timeline():
#   prepare_timeline(data_ae, "Adverse Events (AE)", "AESTDAT", c("AETERM","AESEV"))
#
# To add a new domain, add one more prepare_timeline() call and
# bind_rows() it in — no changes needed elsewhere.
#
# Y-AXIS FORM ORDER
# ------------------
# Controlled by the `levels =` argument when Form is turned into a
# factor in Section 4. Update the vector there to reorder or add rows.
#
# SUBJECT SELECTION
# ------------------
# `selected_subjects` in Section 5 controls which patients are drawn.
# Keep this small (1-3 subjects) — each subject gets its own facet
# panel, so the plot grows tall quickly with more subjects.
#
# OUTPUT FILES
# ------------
#   patient_timeline_plot.png  — high-resolution PNG (300 dpi)
#   patient_timeline_demo.html — self-contained interactive HTML (plotly)
#
# To install optional interactive output:
#   install.packages(c("plotly", "htmlwidgets"))
#
# ============================================================

# ============================================================
# 0. LOAD PACKAGES
# ============================================================
suppressPackageStartupMessages({
  library(dplyr)      # data manipulation
  library(ggplot2)    # plotting
})

# ============================================================
# 1. DUMMY DATA — Replace this section with your own datasets
# ============================================================
set.seed(123)

usubjid_list <- sprintf("%03d-%03d", rep(1:2, each = 5), 1:10)
n_per_subject <- 3
n_total <- length(usubjid_list) * n_per_subject

# Adverse Events
data_ae <- data.frame(
  USUBJID = rep(usubjid_list, each = n_per_subject),
  AESTDAT = as.Date("2023-01-01") + sample(1:150, n_total, replace = TRUE),
  AESEV   = sample(c("Mild", "Moderate", "Severe"), n_total, replace = TRUE),
  AETERM  = sample(c("Headache", "Nausea", "Fatigue"), n_total, replace = TRUE)
)

# Exposure
data_ex <- data.frame(
  USUBJID = rep(usubjid_list, each = n_per_subject),
  EXSTDAT = as.Date("2023-01-05") + sample(1:150, n_total, replace = TRUE),
  EXTRT   = sample(c("Drug A", "Drug B", "Drug C"), n_total, replace = TRUE),
  EXDOSE  = sample(c(50, 75, 100), n_total, replace = TRUE)
)

# Concomitant Medications
data_cm <- data.frame(
  USUBJID = rep(usubjid_list, each = n_per_subject),
  CMSTDAT = as.Date("2023-01-07") + sample(1:150, n_total, replace = TRUE),
  CMTRT   = sample(c("Med A", "Med B", "Med C"), n_total, replace = TRUE),
  CMDOSE  = sample(c(10, 15, 20), n_total, replace = TRUE)
)

# Laboratory (Chemistry)
data_lb <- data.frame(
  USUBJID  = rep(usubjid_list, each = n_per_subject),
  LBDAT    = as.Date("2023-01-10") + sample(1:150, n_total, replace = TRUE),
  LBTEST   = sample(c("ALT", "AST", "BUN"), n_total, replace = TRUE),
  LBSTRESN = round(runif(n_total, 10, 100), 1)
)

# ============================================================
# 2. STANDARDIZATION HELPER
# ============================================================
# Converts ANY dataset into the common timeline format.
#   data         : source data frame
#   form_label   : label shown on the y-axis (one row of the timeline)
#   time_var     : name of the anchor date variable (character)
#   display_vars : variables to show in the tooltip (character vector)
prepare_timeline <- function(data, form_label, time_var, display_vars) {
  df <- data %>% filter(!is.na(.data[[time_var]]))

  info <- df[, c("USUBJID", time_var, display_vars), drop = FALSE]
  info[[time_var]] <- format(info[[time_var]], "%Y-%m-%d")
  tooltip_text <- apply(info, 1, function(row) {
    paste(paste0(names(row), ": ", row), collapse = "<br>")
  })

  df %>%
    mutate(
      Time    = .data[[time_var]],
      Form    = form_label,
      tooltip = tooltip_text
    ) %>%
    select(USUBJID, Time, Form, tooltip)
}

# ============================================================
# 3. STANDARDIZE EACH DOMAIN, THEN STACK
# ============================================================
# To add a domain: write one more prepare_timeline() call and
# list it below — no other section needs to change.
timeline_data <- bind_rows(
  prepare_timeline(data_ae, "Adverse Events (AE)",   "AESTDAT", c("AETERM", "AESEV")),
  prepare_timeline(data_ex, "Exposure (EX)",         "EXSTDAT", c("EXTRT", "EXDOSE")),
  prepare_timeline(data_cm, "Con. Medications (CM)", "CMSTDAT", c("CMTRT", "CMDOSE")),
  prepare_timeline(data_lb, "Laboratory (LB)",       "LBDAT",   c("LBTEST", "LBSTRESN"))
)

# ============================================================
# 4. Y-AXIS FORM ORDER — top to bottom
# ============================================================
form_levels <- c("Adverse Events (AE)", "Exposure (EX)",
                  "Con. Medications (CM)", "Laboratory (LB)")

timeline_data$Form <- factor(timeline_data$Form, levels = rev(form_levels))

# ============================================================
# 5. SUBJECT SELECTION
# ============================================================
# Keep small — each subject gets its own facet panel.
selected_subjects <- c("001-001", "001-002")

plot_data <- timeline_data %>%
  filter(USUBJID %in% selected_subjects)

# ============================================================
# 6. COLOUR + SHAPE SETTINGS
# ============================================================
# One colour AND one shape per data source — redundant encoding so
# domains are still distinguishable in black & white / for colourblind
# readers. Reused across PNG and plotly output.
FORM_COLS <- c(
  "Adverse Events (AE)"   = "#D0021B",  # red    — safety signal
  "Exposure (EX)"         = "#2D9CDB",  # blue   — treatment
  "Con. Medications (CM)" = "#F5A623",  # amber  — concomitant
  "Laboratory (LB)"       = "#1A7F37"   # green  — labs
)

FORM_SHAPES <- c(
  "Adverse Events (AE)"   = 16,  # solid circle
  "Exposure (EX)"         = 15,  # solid square
  "Con. Medications (CM)" = 17,  # solid triangle
  "Laboratory (LB)"       = 18   # solid diamond
)

# --- 6b. AE connecting line ---
# One black line per subject threading through that subject's AE markers,
# in time order. Kept separate (black) from the grey subject-separator
# line added via panel.border in Section 7, so the two don't get confused.
ae_line_data <- plot_data %>%
  filter(Form == "Adverse Events (AE)") %>%
  arrange(USUBJID, Time)

# ============================================================
# 7. PATIENT TIMELINE PLOT
# ============================================================
p_timeline <- ggplot(plot_data,
    aes(x = Time, y = Form, color = Form, shape = Form, text = tooltip)) +

  # Black line threading through each subject's AE markers — drawn first
  # so the points render on top of it.
  geom_line(data = ae_line_data,
            aes(x = Time, y = Form, group = USUBJID),
            color = "black", linewidth = 0.6, inherit.aes = FALSE) +

  geom_point(size = 3, alpha = 0.85) +

  scale_color_manual(values = FORM_COLS, drop = FALSE) +
  scale_shape_manual(values = FORM_SHAPES, drop = FALSE) +

  # Pin the y-axis order explicitly. Without this, ggplot's discrete
  # scale can be thrown off by the AE-only geom_line layer above: when a
  # layer with a partial factor subset trains the scale before a layer
  # with the full set, whichever category it saw first gets sorted
  # first — silently breaking the Section 4 factor level order.
  scale_y_discrete(limits = rev(form_levels)) +

  scale_x_date(date_labels = "%Y-%m-%d", date_breaks = "1 month") +

  facet_wrap(~USUBJID, ncol = 1, strip.position = "left") +

  labs(
    title    = "Patient Timeline — Multi-Domain Event View",
    subtitle = "AE • EX • CM • LB • Dummy data • WinViz Lab / WinSual",
    x = "Date", y = NULL
  ) +

  theme_classic(base_size = 11, base_family = "serif") +
  theme(
    plot.title         = element_text(size = 12, face = "bold",
                                       hjust = 0, margin = margin(b = 3)),
    plot.subtitle      = element_text(size = 8.5, color = "grey50",
                                       hjust = 0, margin = margin(b = 10)),
    axis.text.x        = element_text(size = 9, color = "black",
                                       angle = 45, hjust = 1),
    axis.text.y        = element_text(size = 9, color = "black"),
    strip.text.y.left  = element_text(size = 10, face = "bold", angle = 0),
    strip.background   = element_rect(fill = "grey95", color = NA),
    strip.placement    = "outside",
    panel.grid.major.x = element_line(color = "grey93", linewidth = 0.25),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    # Grey border around each subject's panel — the shared edge between
    # panels is the "separator line" between subjects. Grey, not black,
    # so it reads as structural and never gets confused with the black
    # AE line above.
    panel.border       = element_rect(color = "grey60", fill = NA, linewidth = 0.5),
    panel.spacing.y    = unit(0.8, "lines"),
    legend.position    = "none",
    plot.margin        = margin(12, 16, 8, 10)
  )

# ============================================================
# 8. PREVIEW — RStudio Plots pane (interactive use only)
# ============================================================
# Sending the plot to the *active* graphics device here (before any
# png()/dev.off() block below) is what makes it show up in RStudio's
# Plots pane. Section 9's png() device is a separate, file-only device —
# anything printed while it's open never reaches the Plots pane.
# Guarded by interactive() so a batch run (Rscript/CI) doesn't fall back
# to opening a stray Rplots.pdf for this preview.
if (interactive()) print(p_timeline)

# ============================================================
# 9. EXPORT — PNG + Interactive HTML
# ============================================================

# --- 9a. PNG ---
png_path <- "patient_timeline_plot.png"

# Height scales with number of subjects (facet panels) x number of Forms
n_subj <- length(unique(plot_data$USUBJID))
png_h  <- max(1800, n_subj * 900)

png(filename = png_path, width = 3000, height = png_h, res = 300, bg = "white")
print(p_timeline)
dev.off()

cat("PNG saved to:", png_path, "\n")

# --- 9b. Interactive HTML (optional) ---
if (requireNamespace("plotly", quietly = TRUE)) {
  p_interactive <- plotly::ggplotly(p_timeline, tooltip = "text")

  # ggplotly() always draws facet strip labels centred along the TOP of
  # each panel — it does not honour ggplot2's strip.position = "left"
  # (a known ggplotly limitation, confirmed by inspecting
  # p_interactive$x$layout$annotations). It also draws the strip
  # background as a separate grey `rect` shape, which is left behind
  # (empty) once the label text is moved. Fix both: drop the leftover
  # grey strip-background shapes, and move + restyle the subject-ID
  # annotations into a boxed label to the left of each panel.
  is_strip_bg <- vapply(
    p_interactive$x$layout$shapes,
    function(s) identical(s$fillcolor, "rgba(242,242,242,1)"),
    logical(1)
  )
  p_interactive$x$layout$shapes <- p_interactive$x$layout$shapes[!is_strip_bg]

  yaxis_names <- grep("^yaxis", names(p_interactive$x$layout), value = TRUE)
  panel_centers <- vapply(
    yaxis_names,
    function(nm) mean(p_interactive$x$layout[[nm]]$domain),
    numeric(1)
  )

  ann <- p_interactive$x$layout$annotations
  for (i in seq_along(ann)) {
    if (!is.null(ann[[i]]$text) && ann[[i]]$text %in% selected_subjects) {
      nearest             <- names(which.min(abs(panel_centers - ann[[i]]$y)))
      ann[[i]]$text       <- paste0("<b>", ann[[i]]$text, "</b>")
      ann[[i]]$y          <- unname(panel_centers[nearest])
      ann[[i]]$x          <- -0.06
      ann[[i]]$xanchor    <- "right"
      ann[[i]]$yanchor    <- "middle"
      ann[[i]]$textangle  <- 0
      ann[[i]]$font$size  <- 14
      ann[[i]]$bgcolor    <- "rgba(242,242,242,1)"
      ann[[i]]$borderpad  <- 6
    }
  }
  p_interactive$x$layout$annotations <- ann
  p_interactive$x$layout$margin$l    <- 120  # room for the moved labels

  if (requireNamespace("htmlwidgets", quietly = TRUE)) {
    html_path <- "patient_timeline_demo.html"
    htmlwidgets::saveWidget(p_interactive, html_path, selfcontained = TRUE)
    cat("Interactive HTML saved to:", html_path, "\n")
  }
}

# --- 9c. Console summary ---
cat("========================================\n")
cat("Patient Timeline — Data Summary\n")
cat("----------------------------------------\n")
cat("Subjects shown  :", n_subj, "\n")
timeline_data %>% count(Form) %>% print()
cat("========================================\n")
