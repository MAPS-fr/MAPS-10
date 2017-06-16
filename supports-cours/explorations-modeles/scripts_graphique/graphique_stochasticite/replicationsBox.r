if("readr" %in% rownames(installed.packages()) == FALSE) {install.packages("readr", repos = "http://cran.rstudio.com/", dep=TRUE)}
if("ggplot2" %in% rownames(installed.packages()) == FALSE) {install.packages("ggplot2", repos = "http://cran.rstudio.com/", dep=TRUE)}
if("tools" %in% rownames(installed.packages()) == FALSE) {install.packages("tools", repos = "http://cran.rstudio.com/", dep=TRUE)}
if("dplyr" %in% rownames(installed.packages()) == FALSE) {install.packages("dplyr", repos = "http://cran.rstudio.com/", dep=TRUE)}


# #clean workspace
rm(list=ls(all=TRUE)) 
# #large display
options(width=300)

library(readr)
library(ggplot2)
library(tools)
library(dplyr)

args <- commandArgs(TRUE)
inPath <- file_path_as_absolute(args[1])
outPath <- file_path_as_absolute(args[2]) 

  
repli10 <- read.csv(file.path(inPath,"ants_100s_10r.csv"),sep = ",")
repli50 <- read.csv(file.path(inPath,"ants_100s_50r.csv"),sep = ",")
repli100 <- read.csv(file.path(inPath,"ants_100s_100r.csv"),sep = ",")
repli1000 <- read.csv(file.path(inPath,"ants_100s_1000r.csv"),sep = ",")

medFood1resume <- select(repli10, "10" = medFood1 ) %>% 
  bind_cols(select(repli50,"50" = medFood1 )) %>% 
  bind_cols(select(repli100,"100" = medFood1 )) %>% 
  bind_cols(select(repli1000,"1000" = medFood1 ))

medFood2resume <- select(repli10, "10" = medFood2 ) %>% 
  bind_cols(select(repli50,"50" = medFood2 )) %>% 
  bind_cols(select(repli100,"100" = medFood2 )) %>% 
  bind_cols(select(repli1000,"1000" = medFood2 ))

medFood3resume <- select(repli10, "10" = medFood3 ) %>% 
  bind_cols(select(repli50,"50" = medFood3 )) %>% 
  bind_cols(select(repli100,"100" = medFood3 )) %>% 
  bind_cols(select(repli1000,"1000" = medFood3 ))

colnames(medFood1resume) <- sub(pattern="X", replacement="", x=colnames(medFood1resume))

svg("medFood1.svg")
boxplot(medFood1resume,data=medFood1resume, main="Médiane sur l'objectif food1 sur 100 séries de réplications",
        xlab="Nombre de réplications par série", ylab="Objectif medianFood1") 
dev.off()

svg("medFood2.svg")
boxplot(medFood2resume,data=medFood2resume, main="Médiane sur l'objectif food2 sur 100 séries de réplications",
        xlab="Nombre de réplications par série", ylab="Objectif medianFood2") 
dev.off()

svg("medFood3.svg")
boxplot(medFood3resume,data=medFood3resume, main="Médiane sur l'objectif food2 sur 100 séries de réplications",
        xlab="Nombre de réplications par série", ylab="Objectif medianFood3") 
dev.off()

