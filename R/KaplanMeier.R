# @file KaplanMeier.R
#
# Copyright 2014 Observational Health Data Sciences and Informatics
#
# This file is part of CohortMethod
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Create a Kaplan-Meier plot using ggplot2
#
# @author Adapted from Abhijit Dasgupta with contributions by Gil Tomas
# \url{http://statbandit.wordpress.com/2011/03/08/an-enhanced-kaplan-meier-plot/}
# slight adjustment to cope with none strata calls (e.g. Surv(time,event)~1), 
# option to remove the legend and also draw marks at censoring locations by Nadieh Bremer
.ggkm <- function(sfit,
                 marks = TRUE,
                 legend = FALSE,
                 labelsInGraph = TRUE) {
    
  ystratalabs=c("Comparator","Treated")
  xlabs = "Time in days"
  ylabs = "Survival Probability"
  xlims = c(0,max(sfit$time))
  ylims = c(0,1)
  main = "Kaplan-Meier Plot"
  ystrataname <- "Strata"
  
  #################################
  # sorting the use of subsetting #
  #################################
  
  if(length(levels(summary(sfit)$strata)) == 0) {
    subs2 <- 1:length(summary(sfit,censored=T)$time)
  } else {
    subs2 <- 1:length(summary(sfit,censored=T)$strata)
  }
  
  ##################################
  # data manipulation pre-plotting #
  ##################################
  
  if(length(levels(summary(sfit)$strata)) == 0) {
    #[subs1]
    if(is.null(ystratalabs)) ystratalabs <- as.character(sub("group=*","","All"))
  } else {
    #[subs1]
    if(is.null(ystratalabs)) ystratalabs <- as.character(sub("group=*","",names(sfit$strata)))
  }
  
  m <- max(nchar(ystratalabs))
  
  if(length(levels(summary(sfit)$strata)) == 0) {
    Factor <- factor(rep("All",length(subs2)))
  } else {
    Factor <- factor(summary(sfit, censored = T)$strata[subs2])
  }
  
  #Data to be used in the survival plot
  .df <- data.frame(
    time = sfit$time[subs2],
    n.risk = sfit$n.risk[subs2],
    n.event = sfit$n.event[subs2],
    n.censor = sfit$n.censor[subs2],
    surv = sfit$surv[subs2],
    strata = Factor,
    upper = sfit$upper[subs2],
    lower = sfit$lower[subs2]
  )
  
  #Final changes to data for survival plot
  levels(.df$strata) <- ystratalabs
  zeros <- data.frame(time = 0, surv = 1,
                      strata = factor(ystratalabs, levels=levels(.df$strata)),
                      upper = 1, lower = 1)
  .df <- plyr::rbind.fill(zeros, .df)
  d <- length(levels(.df$strata))
  
  ###################################
  # specifying plot parameteres etc #
  ###################################
  
  p <- ggplot2::ggplot( .df, ggplot2::aes(time, surv,linetype = strata,color = strata)) +
    ggplot2::geom_step(size=1) +
    ggplot2::scale_color_manual(values=c(rgb(0,0,0.8,alpha=0.5),rgb(0.8,0,0,alpha=0.5)),guide=FALSE) +
    ggplot2::scale_x_continuous(xlabs, limits = xlims) +
    ggplot2::scale_y_continuous(ylabs, limits = ylims) +
    ggplot2::labs(linetype = ystrataname) +
    ggplot2::ggtitle(main) +
    ggplot2::theme(legend.title = ggplot2::element_blank())
  
  #Removes the legend: 
  if(legend == FALSE) {
    p <- p + ggplot2::theme(legend.position="none")
  }
  
  if (labelsInGraph == TRUE){
    labelX = .90*(xlims[2]-xlims[1]) + xlims[1]
    delta <- abs(.df$time-labelX)
    nearestComparatorRow <- which(delta == min(delta[.df$strata == "Comparator"]) & .df$strata == "Comparator")[1]
    nearestTreatedRow <- which(delta == min(delta[.df$strata == "Treated"]) & .df$strata == "Treated")[1]
    
    yComparator <- .df$surv[nearestComparatorRow]
    yTreated <- .df$surv[nearestTreatedRow]
    if (yComparator > yTreated){
      yComparator <- min(yComparator + .1,1)
      yTreated <- max(yTreated - .1,0)
    } else{
      yComparator <- max(yComparator - .1,0)
      yTreated <- min(yTreated + .1,1)
    }
    
    p <- p + ggplot2::annotate("text",x = labelX, y = yComparator,label = "Comparator", hjust = 1)
    p <- p + ggplot2::annotate("text",x = labelX, y = yTreated,label = "Treated", hjust = 1)
  }
  
  #Add censoring marks to the line:
  if(marks == TRUE)
    p <- p + ggplot2::geom_point(data = subset(.df, n.censor >= 1), ggplot2::aes(x = time, y = surv), shape = "|")
  
  return(p)
}

