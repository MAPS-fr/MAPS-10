extensions
[
  nw  ;add extension for graph operation
  gis ;add extension to import/export the "mnt" as a raster file.
]

;create a turtles classe named buildinds/antennas/rescues/telecoms and a link classe named roads
breed [buildings building]
breed [antennas antenna]
breed [rescues rescue]
breed [telecoms telecom]
undirected-link-breed [roads road]

patches-own ; define patches atributs
[
  pzcor ; elevation
  ground ; river, hill
  flood ; no = 0 / yes = 1
  id_antenna ; antenna id
  active_antenna ; no = 0 / yes = 1
]

antennas-own ; define antennas atributs
[
  active ; no = 0 / yes = 1
  antenna_priority ; from 1 to 3 // not used in this version of the model
]

buildings-own ; define building atributs
[
  safe ; 1 = yes 0 = no
  nbr_pop ; number of population in the building
  zcor ; elevation
]

rescues-own ; define rescue atributs
[
  location ; coordonate of the patch where i am
  com ; no = 0 (no antenna active at my locatio) / yes = 1
  cible ; coordonate of the patch where i should go
  mission ; count the total of mission realized
]

telecoms-own ; define telecoms atributs
[
  location ; coordonate of the patch where i am
  com ; no = 0 (no antenna active at my locatio) / yes = 1
  cible ; coordonate of the patch where i should go
  mission ; count the total of mission realized
]


globals ; define global variables
[
  x_river ; position of the river (edge or middle)
  width_river ; width of the river
  hill_radius ; radius usded to create hills
  grid ; space between each building in the city
  nbr_diff ; number of repetition of the function "diffuse"
  z_diff ; % used for the function "diffuse" for the land creation
  water_height ; varible used to represent the water height during the simulation
  max_water_height ; maximum elevation of water height
  water_rize ; define how much water height rize on one tick
  mnt ; name of the raster file exported/imported
  listbat ; list of the building to saved => used by the rescues to select a cible
  listantenna ; list of the antenna to saved => used by the telecoms to select a cible
  stop_flood ; siwtch
  end_sim ; siwtch
  pop_total ; result that gives the population totale
  pop_flood ; result that gives the flooding population
  pop_saved ; result that gives the population saved
  flooding ; result that gives the max % of the city touched by the flooding event
  time_end ; result that record the final number of ticks
]

to set_globals ; gives values to gobal vaiables
  ifelse river_location = "edge"
  [
    set x_river 0 ; river on the left edge
  ]
  [
    set x_river 42 ; river on the middle inbetween two buildings raw
  ]
  set width_river 4
  set hill_radius 15
  set grid 10
  set nbr_diff 10
  set z_diff 0.5
  set water_height z_river ; water height start at the water level
  set listbat [] ; to set listbat as empty
  set listantenna [] ; to set listantenna as empty
  set pop_flood 0
  set pop_saved 0
  set pop_total 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; List of function to set color or shape ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set_color_ground ; function to set color to patchs
  ask patches with[ground = "river"]
  [
    set pcolor blue
  ]
end

to set_color_flood ; function to set color to patchs if they are flooding
  ask patches with[flood = 1]
  [
    set pcolor blue
  ]
end

to set_color_mnt ; function to set color to patchs according to their elevation
  ask patches
  [
    set pcolor scale-color brown pzcor (z_max + 5) z_river ; set color to the elevation
  ]
end

to set_color_radius ; function to show the radius of the antena
  ; This function put color with transparancy.
  ; It works by adding a red or green filter to the actual pcolor
  ask patches with[active_antenna = 0]
  [
    let color_patche extract-rgb pcolor
    let R ((item 0 color_patche) + 50)
    let G ((item 1 color_patche) + 0)
    let B ((item 1 color_patche) + 0)
    set pcolor approximate-rgb R G B
  ]
  ask patches with[active_antenna > 0]
  [
    let color_patche extract-rgb pcolor
    let R ((item 0 color_patche) + 0)
    let G ((item 1 color_patche) + 50)
    let B ((item 1 color_patche) + 0)
    set pcolor approximate-rgb R G B
  ]
end

to set_color_building ; function to set color to buildings
  ask buildings with [safe = 1]
  [
    set color green
  ]
   ask buildings with [safe = 0]
  [
    set color red
  ]
     ask buildings with [safe = 2]
  [
    set color yellow
  ]
end

to set_color_antenna ; function to set color to antennas
  ask antennas with[active = 1]
  [
    set color green
  ]
   ask antennas with[active = 0]
  [
    set color red
  ]
  ask antennas with[active = 2]
  [
    set color yellow
  ]
end

to change_icone_rescue ; function to change shape of rescues when they move from ground to water
  if ([flood] of patch-here) = 1
  [
    set shape "rescue_boat"
  ]
end

to change_icone_rescue_2 ; function to change shape of rescues when they move from water to ground
  if ([flood] of patch-here) = 0
  [
    set shape "ambulance"
  ]
end

to change_icone_antenna ; function to change shape of telecoms when they move from ground to water
  if ([flood] of patch-here) = 1
  [
    set shape "antenna_boat"
  ]
end

to change_icone_antenna_2 ; function to change shape of telecoms when they move from water to ground
  if ([flood] of patch-here) = 0
  [
    set shape "antenna"
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; functions calls by the buttoms ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup ; setup general
  clear-all
  nw:set-context buildings roads ; setup a grid with buildings and roads on witch grid calculation will be run
  set_globals ; setup globals - see above
  set_river
  ifelse city_type = "new_random"
  [
    set_elevation
  ]
  [
    import_mnt
  ]
  create-buidlings ; setup the buildings on the grid
  create-antenna ; setup antennas on some of the buildings
  create-roads ; link buildings with road
  set_flood ; setup the maximum of water table
  set_rescue ; setup team of rescues
  set_telecom ; setup team of telecoms
  reset-ticks
end

to go ; function to run the model
go_rescue ; function to move the rescues teams
go_telecom ; function to move the telecoms teams
go_flood ; function to make flooding
unflood ; function to solve unflodding
if pop_flood = 0 and end_sim = "on" ; test if the simulation ends
[
set time_end ticks
stop
]
tick
end

to setup_land ; Function to create a new land
  set_globals
  set_river
  set_elevation
end

to reset ; Function to reset variable to a standart configuration
  clear-all
  set z_city 25
  set z_max 200
  set nbr_hill 3
end

to show_mission ; Function to display the number of missions realized by each team
  ask rescues
  [
    set size mission ; set size of rescue proportional to the number of mission realized
    set label mission
  ]
    ask telecoms
  [
    set size mission * 2 ; set size of telecom proportional to the number of mission realized
    set label mission
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; functions to build the city ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set_river ; function to build the river
  ask patches with [pxcor > x_river and pxcor < (x_river + width_river)]
  [
   set ground "river"
   set pzcor z_river
   set flood 1
   set_color_ground
  ]
end

to set_hill ; function to build one hill
  ask one-of patches with [ground != "river" and ground != "hill"] ; select the top of the hill out of the river and an existing hill
 [
  set pzcor z_max
  set ground "hill"
    ask patches with [ground != "river"] in-radius (hill_radius + random 10) ; set hill radius with a random part
    [
      set pzcor (random (z_city - z_river) + z_city)
      set ground "hill"
    ]
  ]
end

to set_elevation ; function to build a virtual "MNT"
  ask patches with [ground != "river"]
  [
  set pzcor (random (z_city - z_river) + z_river)
  ]
  repeat nbr_hill [set_hill]
  repeat nbr_diff [diffuse pzcor z_diff]
  ask patches with [ground = "river"]
  [
    set pzcor z_river
  ]
  set z_max max [pzcor] of patches ; actualized the value of z_max after the diffuse function
  set z_city mean [pzcor] of patches ; actualized the value of z_city after the diffuse function
  set_color_mnt
  set_color_ground
end

to create-buidlings ; Function to create buildings
  ask patches
  [
    if (pxcor = width_river + 1 or (pxcor mod grid = 0 and pxcor != 0)) and pycor mod grid = 0 and pycor != 0 and pycor != 100 ; create a grid
    [
      sprout-buildings 1 ; create one building on each nod of the grid
      [
        set shape "house"
        set size 3
        set safe 1
        set zcor pzcor
        set nbr_pop (10 + random 20) ; set population to be random between 10 and 30
        set pop_total (pop_total + nbr_pop)
      ]
    ]
    set_color_building
  ]
end

to create-antenna ; Function to create antenna
  ask patches
  [
  if (pxcor = width_river + 1 or (pxcor mod 30 = 0 and pxcor != 0)) and pycor mod 30 = 0 and pycor != 0 and pycor != 100 ; place antenna on a regular grid
    [
      sprout-antennas 1 ; create one antenna on each nod selected
      [
        set shape "target"
        set active 1
        set size 4
        set_color_antenna
      ]
    ]
  ]
  ask antennas
  [
    create_buffer_antenna ; call function to assign antenna's id and activity to the patches
  ]
  set_color_antenna
end

to create_buffer_antenna ; function to create the antenna's emision area
    ask patches in-radius (16)
    [
      set id_antenna myself ; links patchs to one antenna
      set active_antenna [active] of myself
    ]
end

to create-roads ; Function to create roads
  ask buildings
  [
    create-roads-with other buildings in-radius 10
    [
      set thickness 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; functions to create teams of rescues and telecoms ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set_rescue ; function to create rescues teams
  ask one-of patches
   [
      sprout-rescues nbr_rescue
      [
        set color white
        set shape "ambulance"
        set size 8
        set cible 0
        set mission 0
        ifelse set_location = "uncentralized"
        [
          set location one-of buildings with [zcor > z_city] ; teams placed on random building with elevation > of the mean city elevation
        ]
        [
          set location one-of buildings with [xcor > x_river + 40 and xcor < x_river + 50 and ycor = 50] ; team placed on one building distant of 40 m for the river
        ]
        move-to location
      ]
    ]
end

to set_telecom ; function to create telecoms teams
  ask one-of patches
   [
      sprout-telecoms nbr_telecom
      [
        set color orange
        set shape "antenna"
        set size 8
        set cible 0
        set mission 0
        ifelse set_location = "uncentralized"
        [
          set location one-of buildings with [zcor > z_city] ; teams placed on random building with elevation > of the mean city elevation
        ]
        [
          set location one-of buildings with [xcor > x_river + 40 and xcor < x_river + 50 and ycor = 50] ; team placed on one building distant of 40 m for the river
        ]
        move-to location
      ]
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; functions to define and run the flooding event ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set_flood   ;  Define max_water_height and water rize for each return period
  if return_period = 10
  [
    set max_water_height z_river + 3
    set water_rize 0.02
  ]
  if return_period = 50
  [
    set max_water_height z_river + 4
    set water_rize 0.05
  ]
  if return_period = 100
  [
    set max_water_height z_river + 6
    set water_rize 0.1
  ]
end

to go_flood ; Function to run the flooding event
  ifelse water_height < max_water_height
  [
   set water_height water_height + water_rize ; makes water rize
   ask patches with [flood = 1]
    [
      ask neighbors with [pzcor < water_height] ; test witch patches may flood
      [
       set flood 1
       ask antennas-here with [active = 1] ; test if there is one antenna here
        [
          set active 0
          ask buildings-here
          [
            set listantenna fput self listantenna ; add antenna to the list of antenna to be saved
          ]
          ask patches with [id_antenna = myself]
          [
            set active_antenna 0 ; asks patches linked with the antenna to lose communication
          ]
          set_color_antenna
        ]
       ask buildings-here with [safe = 1] ; test is there is one building with people here
        [
          set safe 0
          set listbat fput self listbat ; add building to the list of buildings to be saved
          set pop_flood pop_flood + nbr_pop ; count the population touched by the flooding
          set_color_building
        ]
      ]
    ]
    set flooding (count patches with [flood = 1] / count patches) ; count the percentage of patches that flood
    set_color_flood
  ]
  [
    set stop_flood "on" ; if water height is equal to the maximum
  ]
end

to unflood ; function to run the dicrease of water
  if stop_flood = "on" ; test if water height is equal to the maximum water height
  [
    if water_height > z_river ; test if water is still above it's normal elevation
    [
      set water_height (water_height - water_rize)
      ask patches with [flood = 1 and pzcor > water_height] ; test if patches ar unflood
    [
        set flood 0
    ]
      set_color_mnt
      set_color_flood
    ]
    set end_sim "on" ; if water height is equal to the river elevation, allows to end simulation
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; functions to run the rescues and telecoms teams ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go_rescue ; Function to run the rescue teams
  ask rescues
  [
   ifelse cible = 0 ; test if the rescue already has a cible
     [
      ifelse ([active_antenna] of patch-here) > 0 ; test if the recsue has communication
       [
        choice_cible_rescue ; if the rescue doesn't have cible but has communication, select a cible
       ]
       [
        move_random ; if the rescue doesn't have cible and communication, move randomly to a neighbor building
        change_icone_rescue
        change_icone_rescue_2
;        update_building
       ]
     ]
     [
      move_cible_rescue ; if the rescue has a cible, move to the next step to go there
      change_icone_rescue
      change_icone_rescue_2
;      update_building
     ]
   ]
end

to go_telecom ; Function to run the telecom teams
  ask telecoms
  [
   ifelse cible = 0 ; test if the telecom already has a cible
     [
      ifelse ([active_antenna] of patch-here) > 0 ; test if the telecom has communication
       [
        choice_cible_telecom ; if the telecom doesn't have cible but has communication, select a cible
      ]
      [
       move_random ; if the telecom doesn't have cible and communication, move randomly to a neighbor building
       change_icone_antenna
       change_icone_antenna_2
;       update_antenna
      ]
    ]
    [
     move_cible_telecom ; if the telecom has a cible, move to the next step to go there
     change_icone_antenna
     change_icone_antenna_2
;     update_antenna
    ]
  ]
end

to choice_cible_rescue ; Function to make a rescue chose a cible
  ifelse empty? listbat ; test if the list is not empty
   []
   [
    set cible first listbat ; select the first cible of the list (the oldest one)
    set listbat but-first listbat ; remove the selected cible to avoid for an over rescue to select the same cible
   ]
end

to choice_cible_telecom ; Function to make a telecom chose a cible
  ifelse empty? listantenna ; test if the list is not empty
   []
   [
    set cible first listantenna ; select the first cible of the list (the oldest one)
    set listantenna but-first listantenna ; remove the selected cible to avoid for an over telecom to select the same cible
   ]
end

to move_random ; Function to move randomly a team to one of his neighbors
  let new-location-c one-of [road-neighbors] of location
  move-to new-location-c
  set location new-location-c
end

to move_cible_rescue ; Function to mode a rescue to his cible
  ifelse (any? neighbors = cible or location = cible) ; test if my cible if not here or one of my direct neighbors
  [
    move-to cible ; if yes, move to the cible
    update_building ; saved people
    set mission mission + 1
    set cible 0 ; remove cible so the team may select a new cible
  ]
  [ ; if no, select the quickest way to go to the cible
    let b_cible cible ; local variable
    let target 0 ; local variable to record what is the next building to go
    ask buildings-here
    [
     set target first but-first nw:turtles-on-path-to b_cible ; ask the function "turtles-one-path-to" to give the quickest way
    ]
    move-to target ; move to the next step
    set location target ; record here to be my location
  ]
end

to move_cible_telecom ; Function to mode a telecom to his cible
  ifelse (any? neighbors = cible or location = cible) ; test if my cible if not here or one of my direct neighbors
  [
    move-to cible ; if yes, move to the cible
    update_antenna ; fixe antenna
    set mission mission + 1
    set cible 0 ; remove cible so the team may select a new cible
  ]
  [ ; if no, select the quickest way to go to the cible
    let b_cible cible ; local variable
    let target 0 ; local variable to record what is the next building to go
    ask buildings-here
    [
     set target first but-first nw:turtles-on-path-to b_cible ; ask the function "turtles-one-path-to" to give the quickest way
    ]
    move-to target ; move to the next step
    set location target ; record here to be my location
  ]
end

to update_building ; Function to saved the population and update building "state"
  ask buildings-here
   [
    If safe = 0 ; test if the building is flooded
     [
      set safe 2 ; set building to be saved
      set pop_saved pop_saved + nbr_pop ; record the population saved
      set pop_flood pop_flood - nbr_pop
      set_color_building
     ]
  ]
end

to update_antenna ; Function to fix the antenna and update antenna "activity"
  ask antennas-here
   [
    If active = 0 ; test if antenna is flooded
     [
      set active 2 ; set antenna to be fixed
      set_color_antenna
      create_buffer_antenna ; set patched linked with the antenna to have communication again
     ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; functions to import/export a raster  file ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to export_mnt ; function to export pzcor attribut of all patches to a raster file
  gis:set-world-envelope [0 101 0 101] ; set the wworld dimension
  gis:store-dataset gis:patch-dataset pzcor "mnt.asc" ; export patches elevation as a "mnt"
end

to import_mnt ; function to set pzcor to a imported raster file selected in a list (list to be created by exporting mnt files and renaming it"
  if mnt_choice = 1
  [ set mnt gis:load-dataset "mnt1.asc"]
  if mnt_choice = 2
  [ set mnt gis:load-dataset "mnt2.asc"]
  if mnt_choice = 3
  [ set mnt gis:load-dataset "mnt3.asc"]
  if mnt_choice = 4
  [ set mnt gis:load-dataset "mnt4.asc"]
  gis:apply-raster mnt pzcor ; apply the mnt to the patches
  set z_max max [pzcor] of patches ; actualized the value of z_max after the diffuse function
  set z_city mean [pzcor] of patches ; actualized the value of z_city after the diffuse function
  set_color_mnt
  set_color_ground
end

;;;;;;;;;;;;;;;;;;;;;
;;;;;; Authors ;;;;;;
;;;;;;;;;;;;;;;;;;;;;

; Olivier Cortier (ESITC Caen & LETG Caen)
; Natacha Volto (CNRS)
; Laura Lallement (Université Denis Diderot)
; Stéphane Gougeon (EDF Recherche et Développement)
; Jérôme Frémont (EDF Recherche et Développement)
; Papy Ansobi Onsimbie (Université de Kinshasa)
@#$#@#$#@
GRAPHICS-WINDOW
470
25
983
539
-1
-1
5.0
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
100
0
100
1
1
1
ticks
30.0

BUTTON
340
405
450
438
SETUP LAND
setup_land\n
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
995
405
1115
450
NIL
water_height
2
1
11

MONITOR
1120
405
1242
450
NIL
max_water_height
2
1
11

BUTTON
125
265
187
298
Go!
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

TEXTBOX
10
10
160
28
SELECTE CITY
11
0.0
1

CHOOSER
15
410
153
455
river_location
river_location
"edge" "middle"
1

INPUTBOX
160
410
210
470
nbr_hill
3.0
1
0
Number

INPUTBOX
5
480
152
540
z_river
20.0
1
0
Number

INPUTBOX
160
480
307
540
z_max
24.3734685318
1
0
Number

INPUTBOX
315
480
462
540
z_city
21.84125818902668
1
0
Number

CHOOSER
10
105
148
150
Return_period
Return_period
10 50 100
1

TEXTBOX
10
155
160
173
SETUP TEAM
11
0.0
1

TEXTBOX
10
85
160
103
SETUP FLOOD
11
0.0
1

INPUTBOX
10
175
157
235
nbr_rescue
4.0
1
0
Number

BUTTON
225
440
450
473
EXPORT MNT
export_mnt
NIL
1
T
PATCH
NIL
NIL
NIL
NIL
1

CHOOSER
160
30
298
75
mnt_choice
mnt_choice
1 2 3 4
0

MONITOR
1080
355
1157
400
NIL
pop_saved
17
1
11

BUTTON
10
265
117
298
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
995
25
1245
200
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Saved" 1.0 0 -13840069 true "" "plot pop_saved"
"Flood" 1.0 0 -2674135 true "" "plot pop_flood"

PLOT
995
205
1245
350
Flood
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot flooding"

MONITOR
1165
355
1242
400
Population
pop_total
0
1
11

MONITOR
995
355
1072
400
NIL
pop_flood
0
1
11

CHOOSER
320
175
458
220
set_location
set_location
"centralized" "uncentralized"
0

MONITOR
995
455
1115
500
NIL
Time_end
0
1
11

CHOOSER
10
30
148
75
city_type
city_type
"new_random" "existing_mnt"
1

MONITOR
1120
455
1240
500
max % city flood
flooding * 100
2
1
11

TEXTBOX
5
245
155
263
SETUP & GO
11
0.0
1

TEXTBOX
5
390
155
408
CREATE NEW CITY
11
0.0
1

INPUTBOX
165
175
312
235
nbr_telecom
2.0
1
0
Number

BUTTON
10
335
142
368
ANTENNAS
set_color_radius
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
5
315
155
333
DISPLAY
11
0.0
1

BUTTON
150
335
277
368
LAND + FLOOD
set_color_mnt\nset_color_ground\nset_color_flood
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
225
405
335
438
RESET
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
995
505
1240
538
TEAMS MISSIONS
show_mission
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

KiluCrue simule le plan de secours de la population pendant une inondation due à la crue d’une rivière dans une ville. L’objectif est de dimensionner les équipes qui sont chargées d’aller secourir la population en danger. Ces équipes reçoivent des consignes via le réseau de télécommunication. Ces consignes leur permettent de s’orienter dans la ville vers les populations à secourir. Les antennes du réseau de télécommunication qui sont inondées ne peuvent plus transmettre les consignes aux équipes de secours. Des équipes de travaux (télécom) sont chargées d’aller réparer les antennes de télécommunications inondées. 

## HOW IT WORKS

L’eau envahit peu à peu les bâtiments de la ville. Les équipes de secours cherchent à atteindre les populations présentes dans les bâtiments inondés. Lorsqu’une équipe de secours atteint un bâtiment, la population de ce bâtiment est considérée comme secourue, et l’équipe est prête à recevoir la consigne suivante pour aller secourir un autre bâtiment. Les équipes de secours reçoivent des consignes de déplacement si la communication est en service à l’endroit où ils se trouvent. Les antennes de télécommunication inondées ne peuvent plus transmettre ces consignes. Les équipes de travaux (télécom) cherchent à atteindre les antennes de télécommunications inondées. Lorsqu’une équipe de travaux atteint une antenne, celle-ci peut à nouveau transmettre des consignes. 

## HOW TO USE IT

1) Le choix du terrain. L’utilisateur peut ici utiliser une fonction de création de terrain qu’il pourra ensuite exporter sous la forme d’un fichier raster. L’utilisateur peut jouer ici sur différents paramètres (le nombre de colline, la position de la rivière…) pour créer le terrain.
2) La sélection du terrain. L’utilisateur choisi ensuite le fichier raster qu’il souhaite importer pour sa simulation. Il peut aussi choisir de construire directement un nouveau terrain.
3) Le choix de l’aléa. Pour simuler différents niveaux d’inondation l’utilisateur à le choix entre une période de retour de l’aléa de 10, 50 ou 100 ans. Ce paramètre influence la hauteur maximum ainsi que la vitesse de montée des eaux.
4) L’organisation des secours. L’utilisateur peut choisir le nombre d’équipes mises à disposition pour secourir les populations et pour réparer les antennes de télécommunication. Il peut ensuite définir leur localisation initiale dans la ville.
5) A n’importe quel moment il est possible de visualiser l’émission des antennes en sélectionnant le bouton “Antenna” comme mode d’affichage. Les zones qui apparaissent alors en vert sont couvertes par une antenne active, celles en rouge ne sont pas couvertes. 

## THINGS TO NOTICE

La progression de l’eau suit la topologie du terrain. Les équipes de secours et de travaux utilisent un calcul de plus court chemin entre leurs positions courantes et leurs cibles : les bâtiments inondés avec les populations pour les équipes de secours, les antennes de télécommunications inondées pour les équipes de travaux. 

## THINGS TO TRY

L’utilisateur peut faire varier le nombre d’équipes de secours, leur localisation, la période de retour de l’aléa, puis lancer la simulation. On peut alors évaluer l’efficacité du secours et de l’infrastructure de télécommunication en observant le temps nécessaire pour que tous les bâtiments inondés soient secourus. 

## EXTENDING THE MODEL

Les routes inondées pourraient être rendues impraticables pour les équipes de secours pour rejoindre les bâtiments à secourir. Des agents de travaux dédiés à la voirie pourraient alors être déployés pour dégager les routes au fur et à mesure de la progression de l’inondation. 

## NETLOGO FEATURES

KiluCrue utilise les extensions "nw" pour les calculs de plus court chemin et "gis" pour la gestion de la topologie du terrain.

## RELATED MODELS

Déplacement des équipes : Code Examples/Link-Walking Turtles Example

## CREDITS AND REFERENCES

Olivier Cortier (ESITC Caen & LETG Caen)
Natacha Volto (CNRS)
Laura Lallement (Université Denis Diderot)
Stéphane Gougeon (EDF Recherche et Développement)
Jérôme Frémont (EDF Recherche et Développement)
Papy Ansobi Onsimbie (Université de Kinshasa)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

antenna
false
0
Rectangle -955883 true false 30 90 225 195
Polygon -955883 true false 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1184463 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Line -16777216 false 210 90 210 195
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Rectangle -1 true false 30 150 270 165
Line -1 false 240 105 225 60
Circle -7500403 true true 75 180 30
Circle -7500403 true true 240 180 30

antenna_boat
false
0
Polygon -955883 true false 63 162 90 207 223 207 290 162
Rectangle -7500403 true true 60 180 60 210
Rectangle -7500403 true true 90 120 150 165
Line -7500403 true 135 120 135 60
Rectangle -2674135 true false 135 135 135 180
Polygon -1 true false 135 60 90 75 135 90 135 60

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

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

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

rescue_boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -7500403 true true 60 180 60 210
Rectangle -7500403 true true 90 120 150 165
Line -7500403 true 135 120 135 60
Rectangle -2674135 true false 135 135 135 180
Rectangle -2674135 true false 120 150 135 195
Rectangle -2674135 true false 105 165 150 180
Polygon -11221820 true false 135 60 90 75 135 90 135 60

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
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>time_end</metric>
    <metric>flooding</metric>
    <enumeratedValueSet variable="nbr_telecom">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbr_rescue">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Return_period">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set_location">
      <value value="&quot;uncentralized&quot;"/>
      <value value="&quot;centralized&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="city_type">
      <value value="&quot;existing_mnt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mnt_choice">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="river_location">
      <value value="&quot;middle&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="z_city">
      <value value="22.76914028036465"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="z_river">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbr_hill">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="z_max">
      <value value="27.280595531954532"/>
    </enumeratedValueSet>
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
1
@#$#@#$#@
