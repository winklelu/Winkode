# clinic_review.R
# Clinical Data Viewer
# Author: Winkle Lu
# Description: Integrates multiple CRF domains into an interactive clinical data review interface
#              Supports two filter modes: Patient ID and Form & Variables
#              Features: timeline visualization, data listings, and Excel export

library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(openxlsx)

# ── Load data and utility functions ──
source("data_dummy.R")
source("calculate.R")

# ── Maximum number of forms allowed ──
MAX_FORMS <- 5

# ── UI ──
ui <- fluidPage(
  titlePanel("Clinical Data Viewer"),
  
  sidebarLayout(
    sidebarPanel(
      
      # Filter panel
      div(
        style = "background-color: #d4edda; padding: 10px; border-radius: 5px;",
        radioButtons(
          "filter_mode", "Filter Mode",
          choices  = c("Patient ID" = "id", "Form & Variables" = "crf"),
          selected = "id"
        ),
        
        conditionalPanel(
          condition = "input.filter_mode == 'id'",
          selectInput(
            "usubjid", "Select Patient",
            choices  = all_usubjid,
            selected = all_usubjid[1],
            multiple = TRUE
          )
        ),
        
        conditionalPanel(
          condition = "input.filter_mode == 'crf'",
          selectInput(
            "selected_crf", "Source Dataset",
            choices  = c("", setNames(names(form_labels), form_labels)),
            selected = ""
          ),
          selectInput("selected_var",   "Variables to Display", choices = NULL, multiple = FALSE),
          selectInput("selected_value", "Value Selection",      choices = NULL, multiple = TRUE)
        )
      ),
      
      # Form selection panel
      div(
        style = "background-color: #cce5ff; padding: 10px; border-radius: 5px; margin-top: 10px;",
        h3("Select Dataset and Variables"),
        lapply(seq_len(MAX_FORMS), function(i) {
          div(
            style = "border: 1px solid #6c757d; padding: 10px; margin-bottom: 10px; background-color: #e9f5ff;",
            h4(paste("Form", i)),
            selectInput(
              paste0("form", i), "Source Dataset",
              choices  = c("", setNames(names(form_labels), form_labels)),
              selected = ""
            ),
            selectInput(paste0("form", i, "_var_time"), "Anchor Time Variable", choices = NULL),
            selectInput(paste0("form", i, "_var"),      "Variables to Display", choices = NULL, multiple = TRUE)
          )
        }),
        actionButton("submit_btn", "Submit", class = "btn btn-primary")
      )
    ),
    
    mainPanel(
      
      # Timeline chart
      div(
        style = "background-color: #fff3cd; padding: 10px; border-radius: 5px;",
        plotlyOutput("timeline_plot")
      ),
      
      # Data listing and export
      div(
        style = "background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-top: 15px;",
        downloadButton("download_excel", "Download Listing as Excel", class = "btn btn-success"),
        tags$br(), tags$br(),
        uiOutput("tables_ui")
      )
    )
  )
)

# ── Server ──
server <- function(input, output, session) {
  
  submitted    <- reactiveVal(FALSE)
  clicked_point <- reactiveVal(NULL)
  plot_data    <- reactiveVal()
  
  # ── Submit button ──
  observeEvent(input$submit_btn, {
    submitted(TRUE)
  })
  
  # ── Reset submitted state when any input changes ──
  observe({
    input_list <- lapply(seq_len(MAX_FORMS), function(i) {
      list(
        input[[paste0("form", i)]],
        input[[paste0("form", i, "_var_time")]],
        input[[paste0("form", i, "_var")]]
      )
    })
    input$selected_crf
    input$selected_var
    input$selected_value
    input$usubjid
    submitted(FALSE)
  })
  
  # ── Reset state when filter mode switches ──
  observeEvent(input$filter_mode, {
    submitted(FALSE)
    clicked_point(NULL)
    
    # Clear all form selections first
    lapply(seq_len(MAX_FORMS), function(i) {
      updateSelectInput(session, paste0("form", i), selected = "")
      updateSelectInput(session, paste0("form", i, "_var_time"),
                        choices = character(0), selected = character(0))
      updateSelectInput(session, paste0("form", i, "_var"),
                        choices = character(0), selected = character(0))
    })
    
    if (input$filter_mode == "crf") {
      updateSelectInput(session, "usubjid", selected = character(0))
      updateSelectInput(session, "selected_crf", selected = "")
      updateSelectInput(session, "selected_var",
                        choices = character(0), selected = character(0))
      updateSelectInput(session, "selected_value",
                        choices = character(0), selected = character(0))
    } else {
      updateSelectInput(session, "selected_crf", selected = "")
      updateSelectInput(session, "selected_var",
                        choices = character(0), selected = character(0))
      updateSelectInput(session, "selected_value",
                        choices = character(0), selected = character(0))
      updateSelectInput(session, "usubjid",
                        choices = all_usubjid, selected = all_usubjid[1])
    }
  })
  
  # ── CRF filter: update variable list when dataset is selected ──
  observeEvent(input$selected_crf, {
    req(input$selected_crf)
    updateSelectInput(session, "selected_var",
                      choices  = var_labels[[input$selected_crf]],
                      selected = NULL)
    updateSelectInput(session, "selected_value", choices = NULL, selected = NULL)
  })
  
  # ── CRF filter: update value list when variable is selected ──
  observeEvent(input$selected_var, {
    req(input$selected_crf, input$selected_var)
    data <- form_data[[input$selected_crf]]
    if (!input$selected_var %in% names(data)) return()
    updateSelectInput(session, "selected_value",
                      choices  = unique(data[[input$selected_var]]),
                      selected = NULL)
  })
  
  # ── Dynamically update time and display variables for each form ──
  lapply(seq_len(MAX_FORMS), function(i) {
    observeEvent(input[[paste0("form", i)]], {
      req(input[[paste0("form", i)]])
      form_name <- input[[paste0("form", i)]]
      
      if (!is.null(form_name) && form_name %in% names(form_data)) {
        data      <- form_data[[form_name]]
        time_vars <- get_time_vars(data)
        disp_vars <- get_display_vars(data)
        
        updateSelectInput(session, paste0("form", i, "_var_time"),
                          choices  = time_vars,
                          selected = ifelse(length(time_vars) > 0, time_vars[1], NULL))
        updateSelectInput(session, paste0("form", i, "_var"),
                          choices  = disp_vars,
                          selected = NULL)
      } else {
        updateSelectInput(session, paste0("form", i, "_var_time"), choices = NULL)
        updateSelectInput(session, paste0("form", i, "_var"),      choices = NULL)
      }
    })
  })
  
  # ── Filter data based on user selections ──
  filtered_data <- reactive({
    form_selections <- lapply(seq_len(MAX_FORMS), function(i) {
      list(
        form     = input[[paste0("form", i)]],
        time_var = input[[paste0("form", i, "_var_time")]],
        sel_vars = input[[paste0("form", i, "_var")]]
      )
    })
    
    all_forms_empty <- all(sapply(form_selections, function(f) is.null(f$form) || f$form == ""))
    if (all_forms_empty) return(data.frame())
    
    # 決定USUBJID
    if (input$filter_mode == "crf") {
      selected_usubjid <- get_filtered_usubjid(
        form_data, input$selected_crf, input$selected_var, input$selected_value
      )
      if (is.null(selected_usubjid) || length(selected_usubjid) == 0) return(data.frame())
    } else {
      selected_usubjid <- input$usubjid
    }
    
    build_combined_data(
      form_data      = form_data,
      form_labels    = form_labels,
      form_selections = form_selections,
      selected_usubjid = selected_usubjid,
      filter_mode    = input$filter_mode,
      selected_crf   = input$selected_crf,
      selected_var   = input$selected_var,
      selected_value = input$selected_value
    )
  })
  
  # ── Only show data after Submit is clicked ──
  submitted_data <- reactive({
    req(submitted())
    filtered_data()
  })
  
  # ── Timeline chart ──
  output$timeline_plot <- renderPlotly({
    data <- submitted_data()
    validate(need(nrow(data) > 0, "No data available. Please select options and click Submit."))
    
    clicked        <- clicked_point()
    has_click      <- !is.null(clicked)
    
    data$highlight_flag <- as.logical(data$highlight_flag)
    data$highlight_flag[is.na(data$highlight_flag)] <- FALSE
    
    data$click_flag <- FALSE
    if (has_click) {
      data$click_flag <- with(data,
                              as.character(Form) == clicked$Form &
                                USUBJID == clicked$USUBJID &
                                as.Date(Time) == as.Date(clicked$Time)
      )
    }
    
    data$color <- as.character(data$Form)
    data$color[data$highlight_flag] <- "black"
    if (has_click) {
      data$color[data$click_flag] <- "deeppink"
    }
    
    form_levels    <- unique(data$color[!data$color %in% c("black", "deeppink")])
    palette_colors <- setNames(grDevices::hcl.colors(length(form_levels), palette = "Dynamic"), form_levels)
    color_mapping  <- c("black" = "black", "deeppink" = "deeppink", palette_colors)
    
    base_plot <- ggplot(data, aes(x = Time, y = Form, text = tooltip)) +
      geom_point(aes(color = color), size = 3) +
      scale_color_manual(values = color_mapping) +
      scale_x_date(date_labels = "%Y-%m-%d") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(base_plot, tooltip = "text") %>%
      plotly::event_register("plotly_click") %>%
      { .$x$source <- "A"; . }
  })
  
  # ── Click event handler ──
  observeEvent(plotly::event_data("plotly_click", source = "A"), {
    click_data <- plotly::event_data("plotly_click", source = "A")
    if (is.null(click_data)) return()
    
    data <- plot_data()
    if (is.null(data) || nrow(data) == 0) return()
    
    y_levels <- levels(data$Form)
    target_idx <- which(
      as.Date(data$Time) == as.Date(click_data$x) &
        as.integer(data$Form) == round(click_data$y)
    )
    
    if (length(target_idx) > 0) {
      clicked_point(list(
        Form    = as.character(data$Form[target_idx[1]]),
        USUBJID = data$USUBJID[target_idx[1]],
        Time    = as.Date(data$Time[target_idx[1]])
      ))
    }
  })
  
  # ── Data listing UI ──
  output$tables_ui <- renderUI({
    data <- submitted_data()
    plot_data(data)
    validate(need(nrow(data) > 0, ""))
    
    form_groups    <- split(data, data$Form)
    table_outputs  <- lapply(names(form_groups), function(form_name) {
      tagList(
        h3(strong(form_name)),
        dataTableOutput(paste0("table_", gsub("[^A-Za-z0-9]", "_", form_name)))
      )
    })
    do.call(tagList, table_outputs)
  })
  
  # ── Render individual form tables ──
  observe({
    req(submitted())
    data <- submitted_data()
    validate(need(nrow(data) > 0, ""))
    
    form_groups <- split(data, data$Form)
    
    lapply(names(form_groups), function(form_name) {
      table_id <- paste0("table_", gsub("[^A-Za-z0-9]", "_", form_name))
      
      output[[table_id]] <- renderDT({
        df <- form_groups[[form_name]]
        
        # Get selected variables for this form
        selection  <- get_form_selection(input, form_labels, form_name, MAX_FORMS)
        sel_vars   <- selection$selected_vars
        anchor_var <- selection$anchor_var
        
        # Sort by USUBJID then anchor time variable
        if (!is.null(anchor_var) && anchor_var %in% names(df)) {
          df <- df %>% arrange(USUBJID, .data[[anchor_var]])
        } else {
          df <- df %>% arrange(USUBJID)
        }
        
        show_cols <- intersect(c("Group", "USUBJID", sel_vars, anchor_var), names(df))
        
        # Highlight clicked row
        click <- clicked_point()
        highlight_row <- integer(0)
        if (!is.null(click)) {
          highlight_row <- which(
            as.character(df$Form) == click$Form &
              df$USUBJID == click$USUBJID &
              as.Date(df$Time) == click$Time
          )
        }
        
        datatable(
          df[, show_cols, drop = FALSE],
          options = list(
            autoWidth = TRUE,
            rowCallback = JS(sprintf("
              function(row, data, index) {
                if(index === %d) {
                  $(row).css('background-color', '#ffff99');
                }
              }
            ", ifelse(length(highlight_row) > 0, highlight_row[1] - 1, -1)))
          )
        )
      })
    })
  })
  
  # ── Excel export ──
  output$download_excel <- downloadHandler(
    filename = function() {
      paste0("clinical_data_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(submitted())
      data <- submitted_data()
      validate(need(nrow(data) > 0, "No data to export"))
      
      form_groups <- split(data, data$Form)
      wb          <- createWorkbook()
      
      for (form_name in names(form_groups)) {
        df        <- form_groups[[form_name]]
        selection <- get_form_selection(input, form_labels, form_name, MAX_FORMS)
        sel_vars  <- selection$selected_vars
        anchor_var <- selection$anchor_var
        
        show_cols  <- intersect(c("USUBJID", sel_vars, anchor_var), names(df))
        write_df   <- df[, show_cols, drop = FALSE]
        
        sheet_name <- substr(gsub("[^A-Za-z0-9]", "_", form_name), 1, 31)
        addWorksheet(wb, sheetName = sheet_name)
        writeData(wb, sheet_name, write_df)
      }
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
}

shinyApp(ui, server)