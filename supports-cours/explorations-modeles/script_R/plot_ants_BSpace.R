library(readr)
library(ggplot2)
library(plyr)
library(dplyr)

setwd("~/github/MAPS-10/supports-cours/explorations-modeles/")

my.csv <- read_csv("Ants_es experimental-table.csv", skip = 6)
colnames(my.csv) <- c("run.number","evap.","population","diff.","step","sugar_in_word" )

cdata <- ddply(my.csv, c("evap.","diff."), summarise,
               max.time    = max(step),
               mean.time    = mean(step)
)


gg.point <- ggplot(data = cdata)+
  geom_point(aes(x = evap., y = mean.time))+
  geom_smooth(aes(x = evap., y = mean.time))+
  facet_grid(.~diff., labeller=label_both)+
  labs(x = "Evaporation", y = "Avg. time", title = "Ant : results for pop. 150")
gg.point

ggsave("img/my_plot.png", gg.point)
