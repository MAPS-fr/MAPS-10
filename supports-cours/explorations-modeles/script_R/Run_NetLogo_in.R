## Un exemple d'utilisation simple de RNetlogo 
## Formation MAPS10

library("RNetLogo")

#localisaer l'installation de netlogo
nl.path <- "~/app/NetLogo_6.0.1/app"
NLStart(nl.path, gui = FALSE) #lance netlogo avec (TRUE) ou non (FALSE) une gui

##Definition du chemin du modèle
model.path <- "/home/delaye/github/MAPS-10/supports-cours/explorations-modeles/Ants_es.nlogo"
## chargement du modele dans netlogo
NLLoadModel(model.path)

##Parametres
my.pop <- 120
my.diff <- 30
my.evap <- 20


## change parameter
NLCommand("set population ", my.pop)
NLCommand("set diffusion-rate ", my.diff)
NLCommand("set evaporation-rate ", my.evap)

NLCommand("setup")
agent.df<- data.frame() ## data.frame pour stocker les pos des agents
j <- 0
for(i in 1:2000){ ##On fera 2000 itération ?
  NLCommand("go")
  if(j >= 10){ ## à chaque multiple de 10 on sauvegarde la position des agents
    pos.agents <- NLGetAgentSet(c("who","xcor", "ycor","color",
                                  "ticks"), "turtles")
    agent.df <- rbind(agent.df , pos.agents)
    j = 1
  }
  j <- j + 1
  
}

save(agent.df, file = "/home/delaye/github/MAPS-10/simulation.RData")

NLQuit()
