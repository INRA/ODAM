library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinyBS)
library(networkD3)
library(plotly)
library(markdown)

source("R/ui_tabs.R", local=TRUE)

meta <- tags$head(
   HTML('
   <meta http-equiv="cache-control" content="max-age=0" />
   <meta http-equiv="cache-control" content="no-cache" />
   <meta http-equiv="expires" content="0" />
   <meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
   <meta http-equiv="pragma" content="no-cache" />
   '),
   tags$script(type="text/javascript", src = "js/google-analytics.js"),
   tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
   # Load D3.js
   tags$script(src = "js/d3.min.js")
)

busyLogo <- function(busysrc, height = 30, width = 30, alt = NULL) {
  tagList(
    tags$head(
      tags$script("setInterval(function(){if ($('html').attr('class')=='shiny-busy') { $('img.busy').show(); } else { $('img.busy').hide(); } },100)")
    ),
    img(class = "busy", src=busysrc,height = height, width = width, alt = alt)
  )
}

ui <- dashboardPage(skin = "blue",

  dashboardHeader(title = "ODAM - Data Explorer", disable = FALSE, # titleWidth = 350, 
         # Collection / Dataset name
            tags$li(h2(textOutput("datasetname"), align = "center"), class = "dropdown"),
            tags$li(img(src="img_00.gif",height = 10, width = 10), class = "dropdown"),
         # Dataset selection
            tags$li(selectInput("inDselect", "", c() ), class = "dropdown inDselect"),
            tags$li(img(src="img_00.gif",height = 10, width = 5), class = "dropdown"),
         # Data subset selection
            tags$li(selectInput("inDSselect", "", c() ), class = "dropdown inDSselect"),
            tags$li(img(src="img_00.gif",height = 10, width = 20), class = "dropdown"),
         # Busy logo
            tags$li(busyLogo('busy.gif'), class = "dropdown")
  ),

  dashboardSidebar(
    #----------------------------------------------------
    # Sidebar Menu
    #----------------------------------------------------
        tags$br(),
        sidebarMenu(
            id="IdMenu",
            menuItem("Subset Information",   tabName = "information",   icon = icon("eye")),
            menuItem("Data Table",   tabName = "datatable",   icon = icon("bar-chart")),
            menuItem("Univariate",   tabName = "univariate",   icon = icon("bar-chart")),
            menuItem("Bivariate",    tabName = "bivariate",    icon = icon("bar-chart")),
            menuItem("Multivariate", tabName = "multivariate", icon = icon("bar-chart")),
            menuItem("About",   tabName = "about",   icon = icon("info-circle"))
        )
  ),

  dashboardBody(
    meta,
    shinyjs::useShinyjs(debug = TRUE, html = FALSE),
    shinyjs::inlineCSS(list(.hideElem = "display: none")),
    shinyjs::inlineCSS(list(.dataTables_info="display: inline")),
    #shinyjs::inlineCSS(list(.cplotbig = "height:800px")),
    #shinyjs::inlineCSS(list(.cplotmed = "height:500px")),

    shinyjs::extendShinyjs("js/app.js"),
    fluidRow(
      bsAlert("ErrAlertMain"),
      tabItems(
      #----------------------------------------------------
      # Information
      #----------------------------------------------------
         ui_infoTab,
      #----------------------------------------------------
      # Data table
      #----------------------------------------------------
         ui_dataTab,
      #----------------------------------------------------
      # Univariate : BoxPlot 
      #----------------------------------------------------
         ui_uniTab,
      #----------------------------------------------------
      # Bivariate : ScatterPlot 
      #----------------------------------------------------
         ui_scatterTab,
      #----------------------------------------------------
      # Multivariate : PCA / ICA
      #----------------------------------------------------
         ui_multiTab,
      #----------------------------------------------------
      # About
      #----------------------------------------------------
         ui_aboutTab
      )
    )
  )
)
