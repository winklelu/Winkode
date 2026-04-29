# calculate.R
# Utility functions: data processing and calculation logic
# Purpose: Core calculation functions for Clinical Data Viewer

library(dplyr)

# ── Get date variables from a dataset ──
get_time_vars <- function(data) {
  names(data)[sapply(data, function(col) inherits(col, "Date"))]
}

# ── Get non-date variables for display selection ──
get_display_vars <- function(data) {
  vars <- names(data)
  vars[!grepl("DAT$", vars)]
}

# ── Get filtered USUBJIDs based on CRF filter criteria ──
get_filtered_usubjid <- function(form_data, selected_crf, selected_var, selected_value) {
  if (is.null(selected_crf) || selected_crf == "" ||
      is.null(selected_var) || selected_var == "" ||
      is.null(selected_value) || length(selected_value) == 0) {
    return(NULL)
  }
  data <- form_data[[selected_crf]]
  if (!selected_var %in% names(data)) return(NULL)

  data %>%
    filter(.data[[selected_var]] %in% selected_value) %>%
    select(USUBJID) %>%
    distinct() %>%
    pull(USUBJID)
}

# ── Combine multiple form datasets into a single data frame ──
build_combined_data <- function(form_data, form_labels, form_selections, selected_usubjid, filter_mode,
                                selected_crf, selected_var, selected_value) {
  all_data <- list()

  for (i in seq_along(form_selections)) {
    form      <- form_selections[[i]]$form
    time_var  <- form_selections[[i]]$time_var
    sel_vars  <- form_selections[[i]]$sel_vars

    if (is.null(form) || form == "" || !form %in% names(form_data)) next
    if (is.null(time_var) || time_var == "") next

    valid_time_vars <- get_time_vars(form_data[[form]])
    if (!time_var %in% valid_time_vars) next

    valid_vars <- names(form_data[[form]])
    sel_vars   <- intersect(sel_vars, valid_vars)
    if (length(sel_vars) == 0) next

    df <- form_data[[form]] %>%
      filter(USUBJID %in% selected_usubjid) %>%
      mutate(
        Time = .data[[time_var]],
        Form = form_labels[[form]]
      ) %>%
      filter(!is.na(Time))

    # Apply highlight flag for CRF filter mode
    df$highlight_flag <- FALSE
    if (filter_mode == "crf" &&
        form == selected_crf &&
        !is.null(selected_var) &&
        selected_var %in% names(df)) {
      match_values <- df[[selected_var]] %in% selected_value
      match_values[is.na(match_values)] <- FALSE
      df$highlight_flag <- match_values
    }

    display_vars <- unique(c(time_var, sel_vars))
    df <- df %>% select(USUBJID, Time, all_of(display_vars), Form, highlight_flag)

    df$tooltip <- apply(
      df[, !(names(df) %in% c("Time", "highlight_flag")), drop = FALSE],
      1,
      function(row) paste(paste0(names(row), ": ", row), collapse = "<br>")
    )

    all_data[[form]] <- df
  }

  if (length(all_data) > 0) {
    result       <- bind_rows(all_data, .id = "Group")
    result$Form  <- factor(result$Form, levels = unique(result$Form))
    return(result)
  } else {
    data.frame(
      USUBJID = character(0),
      Time    = as.Date(character(0)),
      Form    = factor()
    )
  }
}

# ── Get selected variables for a given form (used by table and Excel export) ──
get_form_selection <- function(input, form_labels, form_name, max_forms = 5) {
  selected_vars <- NULL
  anchor_var    <- NULL

  for (i in seq_len(max_forms)) {
    form_key <- paste0("form", i)
    if (!is.null(input[[form_key]]) &&
        input[[form_key]] != "" &&
        !is.null(form_labels[[input[[form_key]]]]) &&
        form_labels[[input[[form_key]]]] == form_name) {
      selected_vars <- input[[paste0("form", i, "_var")]]
      anchor_var    <- input[[paste0("form", i, "_var_time")]]
      break
    }
  }

  list(selected_vars = selected_vars, anchor_var = anchor_var)
}
