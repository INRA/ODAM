    ## Metadata preparation / Data extraction
    getDataMulti <- function(F1, selectLevels, FCOL, selectFCOL, selectVars, scale=FALSE ) {
        # Metadata preparation
        F1name <- as.character(LABELS[LABELS[,1]==F1,2])
        variables <-.C(varnames[.N(selectVars),]$Attribute)
    
        facvals <- data[ , F1]
        if (is.numeric(facvals)) {
            fmt <- paste('%0',round(log10(max(abs(facvals)))+0.5)+3,'.2f',sep='')
            facvals <- as.character(sprintf(fmt, facvals))
        }
        levelFac <- .C( levels(as.factor(facvals)) )
    
        fannot=TRUE
        if (is.null(FCOL) || nchar(FCOL)==0) { FCOL <- F1; fannot=FALSE; }
        FCOL <- tryCatch( { if(length(data[, FCOL ])) FCOL  }, error=function(e) { F1 })
        cfacvals <- as.vector(data[ , FCOL])
        cfacvals[is.na(cfacvals)] <- "NA"
        if (is.numeric(cfacvals)) {
            fmt <- paste('%0',round(log10(max(abs(cfacvals)))+0.5)+3,'.2f',sep='')
            cfacvals <- as.character(sprintf(fmt, cfacvals))
        }
        levelcFac <- .C( levels(as.factor(cfacvals)) )
    
        # Data extraction
        subdata <- cbind( data[ , c(samples,variables)] , facvals, cfacvals )
        #subdata <- na.omit(cbind( data[ , c(samples,variables)] , facvals, cfacvals ))
        # Data imputation
        dataIn <- subdata[, variables ]
        if (scale) dataIn <- scale( dataIn, center=TRUE, scale=TRUE )
        resNIPALS <- pca(as.matrix(dataIn), method = "nipals", center = FALSE)
        subdata[, variables ] <- resNIPALS@completeObs        
        colnames(subdata) <- c ( samples, variables, F1, FCOL)
        # Data selection
        subdata <- subdata[subdata[ , F1 ] %in% levelFac[.N(selectLevels)], ]
        if (fannot && length(selectFCOL)>0) subdata <- subdata[subdata[ , FCOL ] %in% levelcFac[.N(selectFCOL)], ]
        facvals <- subdata[, F1 ]
        list( subdata=subdata, facvals=facvals, variables=variables, F1name=F1name, fannot=fannot )
    }

    #----------------------------------------------------
    # Observer - ERROR
    #----------------------------------------------------
    observe ({
       ERROR$MsgErrorMulti
       if (nchar(ERROR$MsgErrorMulti)>0) {
          createAlert(session, "ErrAlertMulti", "ErrAlertMultiId", title = "", content = ERROR$MsgErrorMulti, append = FALSE, style='danger')
       }
    })


    #----------------------------------------------------
    # Observer - Multivariate
    #----------------------------------------------------
    observe({ tryCatch({
       input$inDselect
       if ( ! is.null(input$inDSselect) && input$inDSselect>0) {
          if ((as.numeric(input$nbComp)==2 && input$multiType=='ICA') || .C(input$multiType) %in% c('COR','GGM') || input$outType != 'IDS' ) {
              updateCheckboxInput(session, "f3D", label = '3D', value = FALSE)
              shinyjs::disable("f3D")
          } else {
              shinyjs::enable("f3D")
          }
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 1:\n", e ); }) })

    observe({ tryCatch({
       input$inDselect
       if ( ! is.null(input$inDSselect) && input$inDSselect>0) {
            if (input$f3D==TRUE) {
                  shinyjs::disable("multiLabels")
                  shinyjs::disable("GBG")
            } else {
                  shinyjs::enable("multiLabels")
                  shinyjs::enable("GBG")
            }
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 2:\n", e ); }) })

    observe({ tryCatch({
       input$inDselect
       if ( ! is.null(input$inDSselect) && input$inDSselect>0) {
          # Annotation
          fa_options <- c("None", .C(features[,2]))
          names(fa_options) <- c('---', .C(features$Description))
          updateSelectInput(session, "multiAnnot", choices = fa_options)
          updateSelectInput(session, "outType", selected="None")
          updateSelectInput(session, "multiType", selected="None")
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 3:\n", e ); }) })

    observe({ tryCatch({
       if ( ! is.null(input$inDSselect) && input$inDSselect>0 ) {
          if ( .C(input$multiType) %in% c('COR','GGM') ) {
             v_options <- c('VARS')
             names(v_options) <- c('Variables')
             updateSelectInput(session, "outType", choices = v_options,  selected="VARS")
          } else {
             v_options <- c('IDS','VARS')
             names(v_options) <- c('Identifiers', 'Variables')
             updateSelectInput(session, "outType", choices = v_options,  selected="IDS")
          }
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 3:\n", e ); }) })

    observe({ tryCatch({
       input$inDselect
       if ( ! is.null(input$inDSselect) && input$inDSselect>0) {
          if (inDSselect != input$inDSselect) getVars(.N(input$inDSselect))
          # First Factor
          f1_options <- .C(facnames[,2])
          names(f1_options) <- .C(facnames$Description)
          if (dim(varnames)[1]>2) {
              updateSelectInput(session, "multiFacX", choices = f1_options)
          }
          # Select the variables to be included in the analysis
          v_options <- c( 1:dim(varnames)[1] )
          names(v_options) <- c(.C(gsub(" \\(.+\\)","",varnames$Description)))
          updateSelectInput(session, "listVars", choices = v_options, selected=v_options)
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 4:\n", e ); }) })

    observe({ tryCatch({
       input$inDselect
       if (! is.null(input$inDSselect) && input$inDSselect>0 && ! is.null(input$multiFacX) && nchar(input$multiFacX)>0) {
          facvals <- data[ , input$multiFacX]
          if (is.numeric(facvals)) {
              fmt <- paste('%0',round(log10(max(abs(facvals)))+0.5)+3,'.2f',sep='')
              facvals <- as.character(sprintf(fmt, facvals))
          }
          levelFac <- .C( levels(as.factor(facvals)) )
          l_options <- c( 1:length(levelFac) )
          names(l_options) <- c(as.character(c(levelFac)))
          updateSelectInput(session, "listLevels", choices = l_options, selected=l_options)
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 5:\n", e ); }) })

    observe({ tryCatch({
       input$inDselect
       if (! is.null(input$inDSselect) && input$inDSselect>0 && ! is.null(input$multiAnnot) && nchar(input$multiAnnot)>0) {
          f_options <- c(.C(input$multiAnnot))
          names(f_options) <- c('---')
          if (.C(input$multiAnnot) != "None") {
              fvals <- data[ , input$multiAnnot]
              if (is.numeric(fvals) && sum(is.na(fvals))==0 ) {
                 fmt <- paste('%0',round(log10(max(abs(fvals)))+0.5)+3,'.2f',sep='')
                 fvals <- as.character(sprintf(fmt, fvals))
              }
              flevels <- .C( levels(as.factor(fvals)) )
              if (length(flevels)<nbopt_multiselect) {
                  f_options <- c( 1:length(flevels) )
                  names(f_options) <- c(as.character(c(flevels)))
              }
          }
          updateSelectInput(session, "listFeatures", choices = f_options, selected=f_options)
       }
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("Observer 6:\n", e ); }) })

    #----------------------------------------------------
    # GGM
    #----------------------------------------------------
    observeEvent(c(
        input$multiType,
        input$shrinkauto,
        input$lambda,
        input$qval,
        input$multiAnnot,
        input$multiFacX,
        input$listFeatures,
        input$listLevels,
        input$listVars
    ),{
        if (input$inDSselect==0) return(NULL)
        if (.C(input$multiType)!='GGM') return(NULL)
        FA <- isolate(input$multiAnnot)
        F1 <- .C(isolate(input$multiFacX))
        FCOL <- ifelse( FA=="None", '', FA )
        selectFCOL <- input$listFeatures
        if (nchar(FCOL)>0 && ( length(selectFCOL)==0 || (length(selectFCOL)==1 && selectFCOL[1]==FA) ) ) {
            selectFCOL <- c()
        }
        withProgress(message = 'Calculation in progress', detail = '... ', value = 0, { tryCatch({
             ## Metadata preparation / Data extraction
             o <- getDataMulti(F1, input$listLevels, FCOL, selectFCOL, input$listVars, scale=TRUE)
             #X <- as.matrix(unique( o$subdata[, o$variables, drop = FALSE ]) )
             X <- unique( as.matrix(o$subdata[, o$variables]) )
             n <- dim(X)[1]
             p <- dim(X)[2]

             # Depending on shrink mode, check/estimate  shrinkage intensity lambda
             lambda <- input$lambda
             if (input$shrinkauto>0 || lambda<0) {
                 lambda<-sqrt(2*log(p/sqrt(n))/n)
             }

             out <- FastGGM_Parallel(X, lambda)

             R <-  out$partialCor
             colnames(R) <- colnames(X)
             rownames(R) <- colnames(X)

             # Adjust pvalues 
             P <- p.adjust(out$p_partialCor,method = 'fdr')
             Pm <- matrix(data=P,nrow=dim(R)[1],ncol=dim(R)[2],byrow=TRUE)
             colnames(Pm) <- colnames(X)
             rownames(Pm) <- colnames(X)
             P <- Pm

             # Upper correlation matrix
             cor_mat <- R
             cor_mat[ lower.tri(cor_mat, diag=TRUE) ]<- 0

             # Threshold applied on p-values
             qval <- input$qval
             P[ P > qval ] <- 0
             P[ is.na(P) ] <- 0
             cor_mat[ P==0 ] <- 0

             # Generate the full correlation graph 
             graph <- graph.adjacency(cor_mat!=0, weighted=TRUE, mode="upper")

             # Init. features of edges
             E(graph)$weight<-t(cor_mat)[t(cor_mat)!=0]
             E(graph)[ weight<0 ]$color <- "green"
             E(graph)[ weight>0 ]$color <- "red"

             # Init. features of vertices
             VS <- 1
             V(graph)$size<-rep(VS,length(V(graph)))
             V(graph)$label<- V(graph)$name

             values$netData <<- data.frame(source=as_edgelist(graph)[,1], target=as_edgelist(graph)[,2], Corr=t(cor_mat)[t(cor_mat)!=0])

       }, error=function(e) { ERROR$MsgErrorMulti <- paste("FastGGM :\n", e ); }) })
    })

    output$ggmnet <- renderForceNetwork({
    tryCatch({ ERROR$MsgErrorMulti <- ''; closeAlert(session, "ErrAlertMultiId")
        if (input$inDSselect==0) return(NULL)
        values$launch
        values$netData
        input$gravite
        netData <- values$netData
        Vertices <- unique(sort(c( unique(sort(as.vector(netData[,1]))),  unique(sort(as.vector(netData[,2]))) )))
        V_size <- length(Vertices)
        E_size <- dim(netData)[1]
        Nodesize <- simplify2array(lapply( 1:V_size, function(x) { sum(Vertices[x] == c(as.vector(netData[,1]), as.vector(netData[,2])))^2 }))
    
        L1<-simplify2array(lapply( 1:E_size, function(x) { which( as.vector(netData[,1])[x]==Vertices) }))
        L2<-simplify2array(lapply( 1:E_size, function(x) { which( as.vector(netData[,2])[x]==Vertices) }))
        Links <- data.frame( source=(L1-1), target=(L2-1), value=10*( abs(netData$Corr)-0.3 ) )
        Nodes <- data.frame( name=Vertices, group=rep(1,V_size), size=Nodesize )
        LS <- 1
        link_colors <- rep('Red', E_size); link_colors[which(netData$Corr<0)] <- 'Green'
        fontSize <- 10+5*(LS-1)
        logcharge <- 10*input$gravite-7
        charge <- sign(logcharge)*10^(abs(logcharge))

        forceNetwork(Links = Links, Nodes = Nodes, Source = "source", Target = "target", Value = "value", NodeID = "name", Group = "group", 
                    Nodesize="size", fontSize=fontSize, linkColour=link_colors, charge=charge, 
                    opacity = 0.99, opacityNoHover = 0.99, zoom = TRUE, bounded=TRUE)

    }, error=function(e) { ERROR$MsgErrorMulti <- paste("RenderPlotly:\n", e ); })
    })

    #----------------------------------------------------
    # renderUI - Multivariate : HCA / MDS
    #----------------------------------------------------

    output$Msg <- renderUI({
        if (input$inDSselect==0) return(NULL)
        if (input$inDSselect>0 && dim(varnames)[1]<3) {
            tags$p(class="shiny-output-error","Not enough variables")
        }
    })

    output$MultiPlot <- renderPlotly ({
    tryCatch({ ERROR$MsgErrorMulti <- ''; closeAlert(session, "ErrAlertMultiId")
        if (input$inDSselect==0) return(NULL)
        values$launch
        input$listVars
        input$listLevels
        input$listFeatures
        input$viewComp
        input$nbComp
        FA <- isolate(input$multiAnnot)
        F1 <- .C(isolate(input$multiFacX))
        outputVariables <- ifelse( input$outType == 'IDS', FALSE, TRUE )
        FCOL <- ifelse( FA=="None", '', FA )
        selectFCOL <- input$listFeatures
        if (nchar(FCOL)>0 && ( length(selectFCOL)==0 || (length(selectFCOL)==1 && selectFCOL[1]==FA) ) ) {
            selectFCOL <- c()
        }
        multiType <- input$multiType
        withProgress(message = 'Calculation in progress', detail = '... ', value = 0, { tryCatch({
            if (.C(multiType)=='COR') {
                getCorPLot(F1, selectLevels=input$listLevels, FCOL=FCOL, selectFCOL=selectFCOL, selectVars=input$listVars, full=input$fullmatcor)
            } else if (.C(multiType) %in% c('PCA', 'ICA')) {
                getMultiPLot(multiType, F1, selectLevels=input$listLevels, FCOL=FCOL, selectFCOL=selectFCOL, selectVars=input$listVars, outputVariables, ellipse=input$ellipse, scale=input$scale, blabels=input$multiLabels, f3D=input$f3D, GBG=input$GBG)
            }
       }, error=function(e) {}) })
    }, error=function(e) { ERROR$MsgErrorMulti <- paste("RenderPlotly:\n", e ); })
    })


    #----------------------------------------------------
    # Multivariate : PCA
    #----------------------------------------------------
    PCA_fun <- function(x) {
    
        pc<-prcomp(x,retx=TRUE,scale=F)
        sd <- pc$sdev
        eigenvalues <- sd^2
        evnorm <- (100*eigenvalues/sum(eigenvalues))[1:10]
        Score <- pc$x
        M <- pc$rotation
        if (input$viewComp=="1") { pc1 <- 1;  pc2 <- 2; pc3 <- 3; }
        if (input$viewComp=="2") { pc1 <- 1;  pc2 <- 3; pc3 <- 2; }
        if (input$viewComp=="3") { pc1 <- 2;  pc2 <- 3; pc3 <- 1; }
    
        list(Score=Score, Loadings=M, pc1=pc1, pc2=pc2, pc3=pc3, evnorm=evnorm, prefix='PC' )
    }
    
    #----------------------------------------------------
    # Multivariate : ICA
    #----------------------------------------------------
    ICA_fun <- function(x) {
    
        nbc <- as.numeric(input$nbComp)
        out.ica <- JADE(x, nbc, maxiter = 200)
        Score <- out.ica$S
        M <- t(x)%*%Score
        colnames(Score)<-colnames(M)<-paste("IC", 1:nbc,sep="")
        
        # Kurtosis_order <- F
        # KS <- kurtosis(Score)
        # KSord <- order(KS,decreasing = Kurtosis_order)
        # pc1 <- KSord[1]
        # pc2 <- KSord[2]
        # pc3 <- ifelse(input$nbComp>2, KSord[3], pc1 )

        evnorm <- NULL
        for (i in 1:nbc) {
            evnorm <- c( evnorm, 100*sum(cor(Score[,i],x)^2)/dim(x)[2] )
        }
        evord <- order(evnorm, decreasing=T)
        pc1 <- evord[1]
        pc2 <- evord[2]
        pc3 <- ifelse(input$nbComp>2, evord[3], pc1 )

        list(Score=Score, Loadings=M, pc1=pc1, pc2=pc2, pc3=pc3, evnorm=evnorm, prefix='IC' )
    }


    #----------------------------------------------------
    # Multivariate Plot
    #----------------------------------------------------
    getMultiPLot <- function(Analysis, F1, selectLevels, FCOL, selectFCOL, selectVars, 
                              outputVariables=FALSE, ellipse=TRUE, scale=FALSE, blabels=TRUE, f3D=FALSE, GBG=FALSE) {
        FUN <- ''
        if (nchar(Analysis)>0) FUN <- paste0(Analysis,'_fun')
        if ( ! exists(FUN) ) return(NULL)
    
        ## Metadata preparation / Data extraction
        o <- getDataMulti(F1, selectLevels, FCOL, selectFCOL, selectVars, scale=F)
        subdata<-o$subdata; facvals<-o$facvals; variables<-o$variables; F1name<-o$F1name; fannot<-o$fannot;

        x <- subdata[, variables ]
        if (scale) x <- scale(x)
    
        out <- do.call(FUN, list(x))
        Score <- out$Score
        M <- out$Loadings
        pc1 <- out$pc1
        pc2 <- out$pc2
        pc3 <- out$pc3
        evnorm <- out$evnorm
        prefix <- out$prefix
    
        if (outputVariables==FALSE) {
    
        # Scores plot
           MA <- as.data.frame(cbind( Score[, c(pc1,pc2,pc3)], facvals))
           names(MA) <- c( 'C1','C2', 'C3', 'fac' )
           
           if (! f3D) { # Compute ellipse for each factor level
              centroids <- aggregate(cbind(C1,C2) ~ fac , MA, mean)
              conf.rgn  <- do.call(rbind,lapply(unique(MA$fac),function(t)
                 data.frame(fac=as.character(t),
                           ellipse(cov(MA[MA$fac==t,1:2]),
                                   centre=as.matrix(centroids[centroids$fac==t,2:3]),
                                   level=0.95, npoints=50),
                           stringsAsFactors=FALSE)))
              for( i in 1:length(levels(facvals)) ) conf.rgn$fac[ conf.rgn$fac==i ] <- levels(facvals)[i]
           }
           if (fannot) {
               MA$IDS <- sapply( subdata[ , samples], function (x) { paste(unique(as.vector(subdata[subdata[ , samples]==x, FCOL])),sep="", collapse=',')} )
           } else {
               MA$IDS <- subdata[, samples ]
           }
           names(MA) <- c( 'C1','C2', 'C3', 'fac', 'IDS')
           for( i in 1:length(levels(facvals)) ) MA$fac[ MA$fac==i ] <- levels(facvals)[i]
           MA$fac <- as.factor(MA$fac)

           if (f3D) { # Use 3D plotly
              symbolset = c('dot', 'cross', 'diamond', 'square', 'triangle-down', 'triangle-left', 'triangle-right', 'triangle-up')
              gg <- plot_ly(MA, x = ~C1, y = ~C2, z = ~C3, color = ~fac, 
                 type="scatter3d", marker=list(size = 4), text= ~IDS ) %>%
                 layout(scene = list(xaxis = list(title = sprintf("%s%d = %6.2f%%",prefix, pc1, evnorm[pc1])),
                       yaxis = list(title = sprintf("%s%d = %6.2f%%",prefix, pc2, evnorm[pc2])),
                       zaxis = list(title = sprintf("%s%d = %6.2f%%",prefix, pc3, evnorm[pc3]))))    
           } else { # Use 2D ggplot / plotly
              sizeP <- ifelse( blabels, 0, 0 )
              G1 <- ggplot(data=MA,(aes(x=C1,y=C2,colour = fac)))
              if (!blabels) G1 <- G1 + geom_point(size=sizeP)
              if (blabels) G1 <- G1 + geom_text(aes(label=IDS),hjust=0.5,vjust=0.5)
              if (! is.null(evnorm) ) {
                  G1 <- G1 + xlab(sprintf("%s%d = %6.2f%%",prefix, pc1, evnorm[pc1]))
                  G1 <- G1 + ylab(sprintf("%s%d = %6.2f%%",prefix, pc2, evnorm[pc2]))
              } else {
                  G1 <- G1 + xlab(sprintf("%s%d",prefix, pc1))
                  G1 <- G1 + ylab(sprintf("%s%d",prefix, pc2))
              }
              G1 <- G1 + labs(colour=F1name)
              if (ellipse) G1 <- G1 + geom_path(data=conf.rgn)
              G1 <- G1 + guides(colour = guide_legend(override.aes = list(size=3)))
              if (!GBG) G1 <- G1 + theme_bw()
              gg <- ggplotly(G1)
           }

        } else {

        # Loadings plot - 2D plotly
           
           MA <- as.data.frame(M[, c(pc1,pc2)])
           names(MA) <- c( 'C1','C2' )
           MA$VARS <- rownames(M)
           MA$LABELS <- gsub(" \\(.+\\)","",as.character(LABELS[LABELS[,1] %in% MA$VARS,2]))
           strmode <- ifelse( blabels==TRUE, "text", "markers" )
           names(MA) <- c( 'C1','C2', 'VARS', 'LABELS' )
           gg <- plot_ly(MA, x = ~C1, y = ~C2, color = "blue", type="scatter", mode=strmode, text= ~LABELS ) %>%
                 layout(scene = list(xaxis = list(title = sprintf("%s%d",prefix, pc1)),yaxis = list(title = sprintf("%s%d",prefix, pc2))))
        }
        #htmlwidgets::saveWidget(as.widget(gg), file = "getMultiPLot.html")
        gg
    }


    #----------------------------------------------------
    # Heatmap of correlation matrix
    #----------------------------------------------------
    getCorPLot <- function(F1, selectLevels, FCOL, selectFCOL, selectVars, full=FALSE) {
    
        ## Metadata preparation / Data extraction
        o <- getDataMulti(F1, selectLevels, FCOL, selectFCOL, selectVars, scale=FALSE)
        x <- o$subdata[, o$variables ]

        cormat <- round(cor(x),2)
        dd <- as.dist((1-cormat)/2)
        hc <- hclust(dd)
        cormat <-cormat[hc$order, hc$order]
        if (!full) cormat[lower.tri(cormat)]<- NA
        melted_cormat <- melt(cormat, na.rm = TRUE)
        G1 <- ggplot(data = melted_cormat, aes(Var2, Var1, fill = value))
        G1 <- G1 + geom_tile(color = "white")
        G1 <- G1 + scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                          midpoint = 0, limit = c(-1,1), space = "Lab", name="Pearson\nCorrelation")
        G1 <- G1 + theme_minimal()
        G1 <- G1 + theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 8, hjust = 1))
        G1 <- G1 + coord_fixed()
        gg <- ggplotly(G1)
        #htmlwidgets::saveWidget(as.widget(gg), file = "getMultiPLot.html")
        gg
    }
