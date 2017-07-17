;;;;;;;;;;;;;;;;;;;;;;;;; déclaration des variables globales, des familles et de leurs attributs

globals [
  cell-size
  tick-size
  nb-preys-next-round ;
  number-of-preys-at-ending-point ; nombre de proies parvenant depuis le point de départ au point d'arrivée, sur un cycle
  number-of-cycles ; nombre de cycles (point de départ -> point d'arrivée) que l'on simule
  total-of-preys-killed ; total de proies tuées sur l'ensemble des cycles considérés
]

breed [nodes node]
nodes-own [state]; on attribue un état au noeud en fonction de sa position dans le graphe : 0 = noeud intermédiaire, 1 = noeud départ, 2 = noeud arrivée

breed [preys prey]
preys-own [my-next-node speed-of-walk] ; 2 attributs : le noeud suivant vers lequel la proie se dirige, et sa vitesse de déplacement

breed [traps trap]
traps-own [capacity current-stock] ; 2 attributs : capacité de capture du piège (fixe) et compteur du nombre de proies déjà capturées à un instant dans le cycle


;;;;;;;;;;;;;;;;;;;;;;;;; main

; Initialisation du réseau
to setup-network

  clear-all
  set number-of-cycles 1 ; initialisation du nombre de cycles parcourus
  set total-of-preys-killed 0 ; initialisation du total de proies tuées

  setup-one-node ; positionnement des noeuds sur le plan
  repeat 2 [random-network] ; création des liens entre les noeuds
  setup-states-color-nodes ; détermination de l'état de chacun des noeuds (0, 1 ou 2) et coloration en fonction de ce statut (blanc si 0, rouge si 1 ou 2)
  connect-last-nodes ; on connecte tous les noeuds les plus bas au dernier noeud afin de permettre la percolation
  ask links [ set color white ] ; coloration en blanc des liens entre noeuds
  reset-ticks

end



; Lancement du programme = les proies parcourent le graphe, elles sont éliminées si elles parviennent au point d'arrivée
; puis une pop est régénérée au point de départ pour lancer un nouveau cycle, d'après le nombre de proies parvenues au point d'arrivée au cycle précédent
to go

  ; s'il n'y a plus de proies vivantes sur le graphe on arrête la simulation
  if not any? preys [stop]

  ; on demande aux proies encore en vie si elles sont arrivées au point d'arrivée,
  ; et si oui on les élimine en comptant +1 sur le compteur des proies bien arrivées (méthode finish)
  ask preys
  [
   finish
  ]

  ; si toutes les proies sont arrivées (= toutes "died") on regénère une pop au point de départ
  if not any? preys
  [
    set number-of-cycles number-of-cycles + 1 ; on incrémente le compteur cycle pour savoir où on en est

    ; on arrête la simulation si on a atteint le nombre de cycles max à parcourir, fixé initialement (cf. pb de la résilience)
    if number-of-cycles > max-number-of-cycles
    [
      stop
    ]

    stat-methods ; méthode permettant de comptabiliser le total de proies capturées lors de l'ensemble des cycles

    set number-of-preys-at-ending-point nb-preys-next-round ; on fixe dans une variable le nombre de proies parvenues au point d'arrivée au cycle précédent

    let prey-number-at-starting-point nb-preys-next-round ; on initialise la pop régénérée au point de départ à la valeur du nb de proies arrivées au cycle précédent

    ; on compare la valeur initiale de la pop régénrée à la capacité de charge du milieu
    ; si elle est inf on actualise la valeur initiale en utilisant un taux de croissance de la pop
    ; si elle est sup on fixe la valeur initiale à la capacité de charge
    ifelse prey-number-at-starting-point + prey-number-at-starting-point * growth-rate < carrying-capacity
    [start-preys nb-preys-next-round + nb-preys-next-round * growth-rate]
    [start-preys carrying-capacity]

    set nb-preys-next-round 0 ; à chaque nouveau cycle, on réinitialise cette variable à 0

    ; on réinitialise tous les attributs "stocks en cours" des pièges à 0 à chaque cycle ( = chaque piège est vidé après un cycle)
    ask traps
    [
      set current-stock 0
    ]
  ]

  ; on localise les proies : sont-elles sur un noeud ou sur une arête ?
  ; si elles sont sur un noeud alors on leur demande de choisir individuellement une direction vers un nouveau noeud plus bas, en fonction des possibilités
  locate-preys

  ; on fait avancer les proies
  ; si elles tombent sur un piège, on vérifie si elles se font capturer
  ; si oui on les élimine et on actualise le "stock en cours" des pièges
  ask preys
  [
    fd  speed-of-walk * tick-size / cell-size
    locate-if-preys-on-traps
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;; Méthodes

;;;;;; Méthodes pour l'initialisation du réseau

; méthode qui fixe un état (0, 1 = départ, 2 = arrivée) aux noeuds et les colore en fonction de cet état (blanc si 0, rouge si 1 ou 2)
to setup-states-color-nodes
  ask nodes ; blanc et taille 1.5 par défaut
  [
    set color white
    set size 1.5
  ]
  ask min-one-of nodes [ycor] ; le plus bas est le point d'arrivée = rouge
  [
    set state 2
    set color red
  ]
  ask max-one-of nodes [ycor] ; le plus haut est le point de départ = rouge
  [
    set state 1
    set color red
  ]
end


; méthode qui crée des liens aléatoires entre des noeuds les plus proches, une fois qu'ils ont été placés
to random-network
  ask nodes
  [
    let choice (min-one-of (other turtles with [not link-neighbor? myself and ycor > [ycor] of myself])
                   [distance myself])
    if is-agent? choice [create-link-with choice]
  ]
end

; méthode qui connecte les noeuds les plus bas sans successeurs au noeud d'arrivée,
; afin de permettre la percolation des proies depuis le point de départ, quelque soit le chemin choisi dans le graphe
to connect-last-nodes
  ask nodes with [state = 0] ; on interroge les noeuds intermédiaires entre départ & arrivée
 [
    if not any? link-neighbors with [ycor < [ycor] of myself] ; si ces noeuds n'ont pas de voisin situé plus bas
    [
      create-link-with one-of nodes with [state = 2] ; alors on les relie au noeud d'arrivée
    ]
 ]
end

; méthode qui place les noeuds sur le plan selon des couples de coordonnées tirés aléatoirement
to setup-one-node

  set-default-shape nodes "circle" ; on donne une forme circulaire aux noeuds

  ; on crée autant de noeuds que choisi avec le slider qui fixe "number_of_stations"
  ; en tirant aléatoirement des coordonnées (x,y) pour les noeuds
  ; et en vérifiant qu'il n'y a pas déjà un ou des noeud(s) placés dans le voisinage (distance 2) du couple tiré
  create-nodes number_of_stations
  [
    setxy (random-xcor * 0.95) (random-ycor * 0.95) ; tirage aléatoire des couples (x,y)
    show nodes in-radius 2 ; y a-t-il des noeuds déjà créés dans le voisinage du couple (x,y) tiré ?
    while [( count (nodes in-radius 5)) > 1] [ setxy (random-xcor * 0.95) (random-ycor * 0.95)] ; on retire des couples (x,y) tant qu'il y a au moins un noeud dans le voisinage de distance 2
  ]
end


;;;;;; génération et placement des pièges

; méthode pour placer les traps sur le graphe
to locate-traps


  let listpointxy [] ; initialisation de la liste qui contiendra les couples (x,y) des traps

  ; on identifie les liens sur lesquels se situent n ("numer-of-traps") traps
  ask n-of number-of-traps links
  [
    show self

    let coordx ([xcor] of end2 - [xcor] of end1) ; on récupère les coordonnées des noeuds qui terminent ces liens
    let coordy ([ycor] of end2 - [ycor] of end1)

    let xcormilieu ([xcor] of end1 + coordx  / 2) ; on crée les coord des traps en divisant par 2 = on place les traps au milieu des links
    let ycormilieu ([ycor] of end1 + coordy / 2 )

    set listpointxy lput list xcormilieu ycormilieu listpointxy ; on actualise la liste des (x,y) des traps

   ]


  let index 0 ; index des (x,y) des traps contenus dans "listpointxy"

  ; on place les pièges sur le graphe
  create-traps number-of-traps
  [
    let uniquecouplexy (item index listpointxy) ; retourne un couple (x,y) unique tiré au hasard dans "listpointxy"
    let randomcoordx item 0 uniquecouplexy  ; l'item 0 de ce couple (x,y) correspond à la coordonnée x du trap
    let randomcoordy item 1 uniquecouplexy  ; l'item 1 de ce couple (x,y) correspond à la coordonnée y du trap

    set xcor randomcoordx ; ""utilité ?""
    set ycor randomcoordy ;

    set size 1 ; taille des traps
    set shape "circle" ; forme des traps
    set color green ; couleur des traps

    set index index + 1 ; ""utilité ?""

    set capacity capacity-of-traps ; initialisation de l'attribut de capacité du piège
    set current-stock 0 ; initialisation du stock en cours du piège
  ]
end

;;;;;; Gestion de l'initialisation des proies et de leurs déplacements entre les points de départ et d'arrivée

; méthode d'initialisation des proies
to setup-preys
  set nb-preys-next-round 0 ; initialisation de la variable de comptage des proies arrivées
  start-preys number-of-preys ; initialisation des proies, au nombre de "number-of-preys", positionnées sur le noeud de départ "start"
  reset-ticks
end

; méthode de génération des proies (+ initialisation de leurs attributs) et de leur positionnement sur le noeud de départ
to start-preys [nb]

  ask preys [die] ; on tue les proies encore en vie

  set-default-shape preys "bug" ; on fixe la forme des proies en "bugs"

  let start one-of nodes with [state = 1] ; on démarre au noeud de départ (statut 1), appelé "start"

  ; on crée "nb" proies (slider)
  create-preys nb
  [
    setxy [xcor] of start [ycor] of start ; on place les proies sur les coordonnées du noeud de départ
    set my-next-node start ; on fixe l'attribut "my-next-node" sur le noeud de départ (start)
    set size 1 ; taille des proies
    set color yellow ; couleur des proies
  ]

  ; on fixe la vitesse des proies
  ask preys
  [
    set speed-of-walk 30
  ]

  let max-speed 10 * max [speed-of-walk] of preys
  set cell-size  world-size / max-pxcor
  set tick-size cell-size / max-speed
end


; méthode pour faire évaluer à une proie parvenue à un noeud l'ensemble des directions possibles, en choisir une et s'orienter vers cette direction
to next-node

  ; on identifie le noeud sur lequel se trouve la proie
  let chosen-node nobody
  let next-n one-of nodes with [distance myself < 1]

  ; on identifie ensuite quels sont les noeuds dans le voisinage inférieur du noeud sur lequel se trouve la proie
  ; on choisit au hasard un noeud dans ce voisinage vers lequel se diriger
  ask next-n
  [
      let my-ycor ycor ; on identifie la coord y du noeud sur lequel se trouve la proie
      let next-link link-neighbors with [ycor < my-ycor] ; on identifie les noeuds plus bas que le noeud sur lequel se trouve la proie
      set chosen-node one-of next-link ; on choisit un noeud au hasard dans ce voisinage (loi uniforme)
  ]

  let nd next-n ; ""utilité ?""
  setxy  [xcor] of nd [ycor] of nd ; ""utilité ?""

  set my-next-node chosen-node ; on place dans l'attribut "my-next-node" de la proie la valeur de la variable "chosen-node" = le noeud suivant vers lequel se diriger
  face chosen-node ; on oriente la proie vers le noeud suivant qui vient d'être choisi
end


; méthode pour déteminer si une proie est arrivée sur un noeud ou pas
; lui faire évaluer les directions alors possibles, en choisir une et s'orienter vers celle-ci
to locate-preys
  ask preys
  [
    if  distance my-next-node < 1
    [
      next-node ; cf. méthode précédente
    ]
  ]
end


; méthode pour déterminer si une proie est parvenue au point d'arrivée et ce que l'on doit en faire dans ce cas
to finish
  let finish-node one-of nodes with [state = 2] ; on fixe "finish-node" comme étant le point d'arrivée

  ; si pour une proie la distance au prochain neud est inférieure à 1
  ; et si ce prochain noeud est "finish-node"
  ; alors c'est que la proie est arrivée au point d'arrivée
  ; donc on incrémente le compteur "nb-preys-next-round" qui sert à générer la pop du prochain cycle et on la fait "die"
  if  distance my-next-node < 1
  [
    if finish-node = my-next-node
    [
      set nb-preys-next-round nb-preys-next-round + 1
      die
     ]
   ]
end


;;;;;; Gestion des passages des proies sur un piège

; méthode de détermination de l'efficacité de la capture d'une proie par un piège
to-report trap-proba
   report (random-float 1) > 0.95 ; renvoie TRUE si le tirage "random-float 1" donne une valeur > à 0.95 (= la proba d'échapper au trap, 95%)
end


; méthode de détermination du taux de remplissage d'un piège, vis-à-vis de sa capacité maximale
to-report trap-filled
  let res FALSE
  ask traps-here
  [
    set res current-stock < capacity ; "res" vaut TRUE si le piège n'a pas encore atteint sa capacité maximale
  ]
  report res
end


; méthode de détermination de la capture d'une proie par un piège et de ses csq pour la proie
to locate-if-preys-on-traps
  if  any? traps-here ; s'il y a un piège dans le voisinage de la proie
  [
    if trap-proba = TRUE and trap-filled = TRUE ; si ce piège capture la proie et qu'il n'est pas plein
    [
      ask traps-here
      [
        set current-stock current-stock + 1 ; alors on incrément le stock-en-cours du piège de 1
      ]
      die ; et on élimine la proie
    ]
   ]
end


;;;;;;; Gestion des outputs statistiques du modèle

; méthode de comptage du total de proies capturées tout au long de plusieurs cycles
to stat-methods
    set total-of-preys-killed total-of-preys-killed + sum [ current-stock ] of traps
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
881
682
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
50
0
50
0
0
1
ticks
30.0

SLIDER
12
159
184
192
number_of_stations
number_of_stations
0
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
12
199
125
232
Setup Network
setup-network
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
445
182
478
number-of-preys
number-of-preys
0
10000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
9
89
181
122
world-size
world-size
1
100
100.0
1
1
km
HORIZONTAL

BUTTON
9
625
107
658
setup-preys
setup-preys
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
17
138
167
156
NETWORK
11
0.0
1

TEXTBOX
15
419
165
437
PREYS
11
0.0
1

BUTTON
907
13
970
46
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
274
185
307
number-of-traps
number-of-traps
0
40
0.0
1
1
NIL
HORIZONTAL

BUTTON
12
314
131
347
NIL
locate-traps
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
897
58
987
103
NIL
count preys
17
1
11

PLOT
1235
323
1445
518
Total number of preys
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count preys"

PLOT
1136
33
1573
293
Total of preys at ending point by cycle
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot number-of-preys-at-ending-point"

INPUTBOX
10
489
172
549
carrying-capacity
1200.0
1
0
Number

INPUTBOX
9
558
171
618
growth-rate
0.25
1
0
Number

TEXTBOX
20
253
208
276
TRAPS
12
0.0
1

TEXTBOX
14
70
202
93
WORLD
12
0.0
1

TEXTBOX
37
17
225
40
INITIALIZATION
15
0.0
1

SLIDER
10
356
189
389
capacity-of-traps
capacity-of-traps
0
100
41.0
1
1
NIL
HORIZONTAL

MONITOR
896
178
1036
223
NIL
total-of-preys-killed
17
1
11

INPUTBOX
8
678
170
739
max-number-of-cycles
5.0
1
0
Number

MONITOR
896
118
1024
163
NIL
number-of-cycles
17
1
11

MONITOR
895
232
1121
277
NIL
number-of-preys-at-ending-point
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-nbtraps-capacitytraps" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-network
locate-traps
setup-preys</setup>
    <go>go</go>
    <metric>total-of-preys-killed</metric>
    <metric>number-of-cycles</metric>
    <metric>number-of-preys-at-ending-point</metric>
    <steppedValueSet variable="capacity-of-traps" first="1" step="10" last="50"/>
    <steppedValueSet variable="number-of-traps" first="1" step="1" last="5"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
