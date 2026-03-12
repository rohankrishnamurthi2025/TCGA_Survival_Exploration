# Rohan Krishnamurthi Project: app.R script
#3/10/2026

# Load Packages
library(tidyverse)
library(shiny)
library(DT)
library(plotly)
library(bslib)
library(survival)
library(survminer)
library(ggsurvfit)

# install.packages(c("lubridate", "ggsurvfit", "gtsummary", "tidycmprsk"))
library(lubridate)
library(gtsummary)
library(tidycmprsk)

# devtools::install_github("zabore/condsurv")
library(condsurv)

# install.packages("broom.helpers")
library(broom.helpers)

# Set working directory and import relevant data
getwd()
brca_patient_data_processed <- read.csv("data/brca_patient_data_processed.csv", header = TRUE)
coad_patient_data_processed <- read.csv("data/coad_patient_data_processed.csv", header = TRUE)


# List of Relevant Variables:
# bcr_patient_uuid, vital_status, gender, ethnicity, race
# history_neoadjuvant_treatment, radiation_treatment_adjuvant, pharmaceutical_tx_adjuvant (Yes/No)
# ajcc_pathologic_tumor_stage, anatomic_neoplasm_subdivision,
# days_to_patient_progression_free, days_to_tumor_progression, days_to_initial_pathologic_diagnosis
# age_group, stage, status, time, histologic_diagnosis, age_at_diagnosis
# lymph_nodes_examined (YES/NO), lymph_nodes_examined_count


genders <- c("FEMALE", "MALE" )
# races <- c("BLACK OR AFRICAN AMERICAN", "WHITE", "ASIAN", "AMERICAN INDIAN OR ALASKA NATIVE", NA)

races <- c(
  "BLACK OR AFRICAN AMERICAN",
  "WHITE",
  "ASIAN",
  "AMERICAN INDIAN OR ALASKA NATIVE"
)
# Previously, include NA as "Undisclosed"    

##### UI SECTION #####

ui <- page_sidebar(	
  title = tags$h1(strong("TCGA Cancer Survival Exploration Tool for Clinical Researchers")),
  sidebar = sidebar(
    #CSS class for sidebar container element
    class = ("bg-success-subtle text-dark p-3"), #"bg-primary-subtle"
    h3("Data Filters", class = "fw-semibold text-primary"),

    # Select Cancer Type
    radioButtons("cancer_type", label = ("Cancer Type"),
                 choices = c("Breast Cancer" = "TCGA-BRCA", "Colon Cancer" = "TCGA-COAD"), 
                 selected = "TCGA-COAD"),
    
    # Select Cancer Stage
    checkboxGroupInput("stage", "Cancer Stage", choices = c("I","II","III","IV"), selected = c("I","II","III","IV")),
    
    # Select Age Range
    sliderInput("age_slider", "Range of Age at Diagnosis", min = 25, max = 100, value = c(25,100)),
    
    # Select Gender
    checkboxGroupInput("gender", "Gender", choices = c("FEMALE", "MALE"), selected = c("FEMALE", "MALE")),
    
    # Select Race
    checkboxGroupInput("race", "Race", choices = races, selected = races),
    
    # Treatments: history_neoadjuvant_treatment, radiation_treatment_adjuvant, pharmaceutical_tx_adjuvant, pharm_regimen
    # Can select for race or ethnicity, family history, anatomic neoplasm subdivision
    
    # Survival Curve Stratification
    selectInput("strata_var", "Stratification Variable:", 
                choices = c("None" = "none", "Stage" = "stage",
                            "Gender" = "gender", "Race" = "race", 
                            "Adjuvant radiation treatment" = "radiation_treatment_adjuvant", 
                            "Adjuvant pharmaceutical treatment" = "pharmaceutical_tx_adjuvant",
                            "Neoadjuvant treatment" = "history_neoadjuvant_treatment"), selected = "none")
    
    ),
  
  navset_tab(
    
    ## First Panel ##
    nav_panel(
      title = "Data Table",
      h2(strong("Filtered Data Table")),
      h5("Select the rows you wish to download separately."),
      # tableOutput("summary_table"), # Optional
      DTOutput("patient_table"), # from DT library, or dataTableOutput
      layout_columns(
        col_widths = c(3, 3),
        downloadButton("download_full", label = "Download full filtered data (CSV)",
                       style = "background-color: green; color: white;"),
        downloadButton("download_selected", label = "Download selected rows (CSV)", 
                       style = "background-color: blue; color: white;")
      )

    ),
    
    ## Second Panel ##
    nav_panel(
      title = "Exploration of Data",
      h2(strong("Exploration of Filtered Data")),
      h5('Select a stratification variable to view data distribution for that variable.'),
      h5("Selected rows in table will illuminate in stratification variable vs. age at diagnosis plot."),
      layout_columns(
        col_widths = c(12),
        # Data distribution by Anatomic Neoplasm Subdivision, bar chart
        card(
          #card_header("Data distribution by Anatomic Neoplasm Subdivision"),
          card_body(plotlyOutput("neoplasm_dist") )
        )
      ),
      layout_columns(
        col_widths = c(6, 6),
        # Data distribution by selected stratification variable, pie chart
        card(
          #card_header("Data distribution by Stratification Variable"),
          card_body(plotlyOutput("stratification_dist"))
        ),
        
        # Data distribution by strat var vs. age at diagnosis, scatterplot
        card(
          #card_header("Stratification Variable vs. Age at Diagnosis"),
          card_body(plotlyOutput("age_dist"))
        )
      )
      
    ),
   
     ## Third Panel ##
    nav_panel(
      title = "Survival Explorer",
      h2(strong('Kaplan-Meier Survival Analysis')),
      h5("Click on a point on a Kaplan-Meier curve below to view the respective"),
      h5("survival probabilities at that time (distinguished by stratification variable)."),
      
      card(
        #card_header("Kaplan-Meier Curve"),
        card_body(plotlyOutput("kaplan_plot_1"))
      ),
      DTOutput("kaplan_click_table"), 
      downloadButton("download_kaplan_plot_1", label = "Download Kaplan-Meier Plot (PNG)",
                     style = "background-color: green; color: white;")
      
    ),
    
    ## Fourth Panel ##
    nav_panel(
      title = "Cox Model",
      tags$body(
        h2(strong('Cox Regression Model')),
        h5('Select a stratification variable to view the Cox regression model output for that variable.'),
        h5("The resulting table contains the variable level, hazard ratio, 95% confidence interval, and p-value.")
      ),
      DTOutput("cox_table")
    )
  ),
                    
)

##### SERVER SECTION  #####

server <- function(input, output, session){
  
  #### CREATE REACTIVE VARIABLES ####
  # Create data table
  filtered_data <- reactive({
    if (input$cancer_type == "TCGA-BRCA"){
      df <- brca_patient_data_processed
    } else if (input$cancer_type == "TCGA-COAD") {
      df <- coad_patient_data_processed
    } else {
      df <- NULL
    }
    
    # Apply stage filter
    #if (!is.null(input$stage)) {df <- df[df$stage %in% input$stage, ]}
    df <- df[df$stage %in% input$stage, ]
    
    # Gender
    #if (!is.null(input$gender)) {df <- df[df$gender %in% input$gender, ]}
    df <- df[df$gender %in% input$gender, ]
    
    # Race
    df <- df[df$race %in% input$race, ]
    
    # Age
    if (length(input$age_slider) == 2) {
      df <- df[df$age_at_diagnosis >= input$age_slider[1] &
                 df$age_at_diagnosis <= input$age_slider[2], ]
    }
    
    df
  })
  
  # Stratification Grouping Variable
  group_var <- reactive({
    var <- input$strata_var
    if (is.null(var) || var == "none") {
      return(NULL)
    }
    factor(filtered_data()[[var]])
  })
  
  
  
  #### PANEL 1 ####
  output$patient_table <- renderDT({
    datatable(filtered_data(), rownames = F, 
              selection = list(mode = "multiple", target = "row"))  
  })
  
  # Full download button
  output$download_full <- downloadHandler( 
    filename = function(){
      "tcga_data_filtered.csv"
    }, 
    content = function(file){
      write.csv(filtered_data(), file)
    } 
  )
  
  # Selected download button
  selected_rows <- reactive({
    # Subset the data based on selected rows in the table
    filtered_data()[input$patient_table_rows_selected, ]
  })
  
  output$download_selected <- downloadHandler( 
    filename = function(){
      "tcga_data_selected.csv"
    }, 
    content = function(file){
      write.csv(selected_rows(), file)
    } 
  )
  
  
  #### PANEL 2 ####
  # Make regular plots or plotly plots
  # Stratification vars: Stage, Race, Gender, Treatment
  
  output$neoplasm_dist <- renderPlotly({
    neoplasm_data <- filtered_data() |> 
      group_by(anatomic_neoplasm_subdivision) |> 
      summarize(count = n())
    
    plot_ly(data = neoplasm_data, y = ~anatomic_neoplasm_subdivision, x = ~count,
            type = "bar", orientation = "h", name = "Distribution of Cases by Neoplasm Subdivision"
    ) |>
      layout(
        title = "Distribution of Cases by Anatomic Neoplasm Subdivision",
        xaxis = list(title   = "Number of Cases"),
        yaxis = list(title = "Anatomic Neoplasm Subdivision")
      )
    
  })
  
  output$age_dist <- renderPlotly({
    df <- filtered_data()
    req(nrow(df) > 0)
    
    strat_var <- input$strata_var
    # If no valid stratification variable is selected, don’t plot
    if (is.null(strat_var) || strat_var == "none" || !(strat_var %in% names(df))) {
      return(NULL)
    }
    
    df <- df |>
      dplyr::mutate(
        .x_jitter = as.numeric(as.factor(.data[[strat_var]])) +
          runif(dplyr::n(), -0.1, 0.1)  # small random offset
      )
    
    # Base marker style
    base_color <- "rgba(0, 123, 255, 0.4)"  # light blue
    base_size  <- 6
    
    # Initialize all points as base color/size
    colors <- rep(base_color, nrow(df))
    sizes  <- rep(base_size,  nrow(df))
    
    # If there are already selected rows in the table, highlight them
    sel <- input$patient_table_rows_selected
    if (!is.null(sel) && length(sel) > 0) {
      colors[sel] <- "#FF4500"   # bright orange
      sizes[sel]  <- 9
    }
    
    plot_ly(
      data  = df,
      x     = ~.x_jitter,
      y     = ~age_at_diagnosis,
      type  = "scatter",
      mode  = "markers",
      text  = ~.data[[strat_var]],
      source = "age_dist",
      marker = list(
        color = colors,   # per-point colors
        size  = sizes,    # per-point sizes
        line  = list(width = 0, color = "white")
      ),
      hovertemplate = paste0(
        strat_var, ": %{text}<br>",
        "Age: %{y}<extra></extra>"
      )
    ) |>
      layout(
        title = paste(strat_var, "vs. Age at Diagnosis"),
        xaxis = list(
          title   = strat_var,
          tickmode = "array",
          tickvals = seq_along(unique(df[[strat_var]])),
          ticktext = sort(unique(df[[strat_var]]))
        ),
        yaxis = list(title = "Age at Diagnosis")
      )
  })

  
  
  
  # Highlight DT selections in scatterplot using proxy
  observeEvent((input$patient_table_rows_selected), {
    df <- filtered_data()
    sel <- input$patient_table_rows_selected
    req(nrow(df) > 0)
    
    colors <- rep("rgba(0, 123, 255, 0.3)", nrow(df))
    sizes  <- rep(6, nrow(df))
    
    if (length(sel) > 0){
      colors[sel] <- "#FF4500"  # bright orange
      sizes[sel]  <- 9
    }
    
    # Plotly Proxy: update scatter data when slider changes
    proxy_age_dist <- plotlyProxy("age_dist", session)
    
    plotlyProxyInvoke(
      proxy_age_dist,
      "restyle",
      list(
        "marker.color" = list(colors),
        "marker.size"  = list(sizes),
        # reinforce the white outline for all points
        "marker.line.color" = list(rep("white", nrow(df))),
        "marker.line.width" = list(rep(1, nrow(df)))
      ),
      0
    )
  }, ignoreInit = T)
  
  
  output$stratification_dist <- renderPlotly({
    if (is.null(group_var())) return(NULL)
    
    df <- filtered_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    strat_var <- input$strata_var
    
    stratified_data <- df %>%
      mutate(.group = group_var()) %>%
      group_by(.group) %>%
      summarise(count = n(), .groups = "drop")
    
    plot_ly(
      data = stratified_data,
      labels    = ~.group,
      values    = ~count,
      type = "pie",
      name = "Distribution of Cases by Stratification Variable"
    )   |>
      layout(
        title = paste("Distribution of Cases by ", strat_var)
      )
    
    
  })
  
  
  #### PANEL 3 ####
  
  
  km_plot <- reactive({
    df <- filtered_data()
    req(nrow(df) > 0)
    
    strat_var <- input$strata_var
    
    if (is.null(group_var())) {
      survfit2(Surv(time, status) ~ 1, data = df) |>
        ggsurvfit() +
        labs(
          title = "Kaplan-Meier Plot",
          x = "Days",
          y = "Overall Survival Probability"
        ) 
    } else {
      stratified_data <- df %>%
        mutate(.group = group_var())
      
      survfit2(Surv(time, status) ~ .group, data = stratified_data) |>
        ggsurvfit() +
        labs(
          title = paste("Kaplan-Meier Plot stratified by", strat_var),
          x = "Days",
          y = "Overall Survival Probability"
        ) 
        # theme(
        #   legend.position = "bottom",
        #   legend.margin   = margin(t = 15),
        #   plot.margin     = margin(b = 40, t = 10)
        # )
    }
  })
  
  output$kaplan_plot_1 <- renderPlotly({
    ggplotly(km_plot(), source = "kaplan_plot_1") |> 
      layout(
        legend = list(
          y = -0.25,          # move legend slightly *below* plotting area
          x = 0.5,
          xanchor = "center",
          orientation = "h"   # horizontal legend
        ),
        margin = list(b = 80) # extra bottom margin for legend + x-axis title
      )
  })
  
  # Plot Click Handling
  
  output$kaplan_click_table <- renderDT({
    
    # Collect the groups of the stratification variable
    df <- filtered_data()
    req(nrow(df) > 0)
    
    # Collect click data
    click_data <- event_data("plotly_click", source = "kaplan_plot_1")
    req(click_data)
    x_val <- (click_data)$x
    
    # Compute the survival probabilities of the stratification groups at the x_value (time)
    # Build survfit based on whether we have a grouping variable
    if (is.null(group_var())) {
      tbl <- tbl_survfit(
        x = survfit(Surv(time, status) ~ 1, data = df),
        times = x_val,
        label_header = paste("Survival Prob. at:", as.character(x_val), "days (and 95% CI)")
      )
      
    } else {
      stratified_data <- df %>%
        mutate(.group = group_var())
      
      fit <- survfit(Surv(time, status) ~ .group, data = stratified_data)
      
      tbl <- tbl_survfit(
        fit,
        times = x_val,
        label_header = paste("Survival Prob. at", as.character(x_val), "days (and 95% CI)")
      )
    }
    
    # Convert gtsummary object to a tibble/data.frame for DT
    tbl_df <- as_tibble(tbl) |> 
      rename("Group" = "**Characteristic**")
    tbl_df <- tbl_df[tbl_df$Group != ".group", ]
    
    datatable(tbl_df,
              rownames = FALSE,
              options = list(pageLength = 10))

  })
  
  
  output$download_kaplan_plot_1 <- downloadHandler(
    filename = function() {
      "kaplan_meier_plot.png"
    },
    content = function(file) {
      ggsave(
        filename = file,
        plot     = km_plot(),
        device   = "png",
        width    = 7,
        height   = 5,
        dpi      = 300
      )
    }
  )
    
  
  #### PANEL 4 ####
  
  # Cox Fit
  # coxph(Surv(time, status) ~ sex, data = lung) |>
  #   tbl_regression(exp = TRUE)

  output$cox_table <- renderDT({
    df <- filtered_data()
    req(nrow(df) > 0)
    
    strat_var <- input$strata_var
    
    # 1) Check that a valid strat_var is selected
    validate(
      need(
        !is.null(strat_var) && strat_var != "none" && strat_var %in% names(df),
        "Must select a stratification variable with at least two levels."
      )
    )
    
    # 2) Drop rows with missing strat_var
    df_model <- df[!is.na(df[[strat_var]]), ]
    validate(
      need(
        nrow(df_model) > 0,
        "Must select a stratification variable with at least two levels."
      )
    )
    
    # 3) Ensure more than one level
    n_levels <- length(unique(df_model[[strat_var]]))
    validate(
      need(
        n_levels >= 2,
        "Must select a stratification variable with at least two levels."
      )
    )
    
    # Build formula: Surv(time, status) ~ strat_var
    form <- as.formula(paste("Surv(time, status) ~", strat_var))
    
    # Fit Cox model
    fit <- coxph(form, data = df_model)
    
    # gtsummary table with hazard ratios
    tbl <- tbl_regression(fit, exp = TRUE)
    
    # Convert gtsummary object to tibble for DT
    tbl_df <- as_tibble(tbl)
    
    datatable(
      tbl_df,
      rownames = FALSE,
      options  = list(pageLength = 10)
    )
  })

}


##### Run Shiny App  #####

shinyApp(ui, server)
