#!/bin/bash

RESULTS=../../scripts_experience/data-book/calibration
OUT=./pics

for i in {1..2000}
do
   gnuplot -e "set terminal jpeg enhanced  font \"arial,8\"; set multiplot layout 3,2 title \"multiplot\" ; set title \"view1\"; 

set title \"Evaporation - Diffusion\"; unset key; set xlabel 'Evaporation'; set ylabel 'Diffusion';set datafile separator ','; set xrange [ 0 : 100 ] noreverse nowriteback ; set yrange [ 0 : 100 ] noreverse nowriteback; set datafile separator ','; plot '$RESULTS/population$i.csv' using (column(\"gDiffusionRate\")):(column(\"gEvaporationRate\"));

    set title \"Food1 - Food2\"; unset key; set xlabel 'Food1'; set ylabel 'Food2';set datafile separator ','; set xrange [ 100 : 800 ] noreverse nowriteback ; set yrange [ 100 : 1300 ] noreverse nowriteback; set datafile separator ','; plot '$RESULTS/population$i.csv' using (column(\"food1\")):(column(\"food2\")); set title \"Food 1 - Food 3\"; unset key; set xlabel 'Food1'; set ylabel 'Food3';set datafile separator ','; set xrange [ 100 : 800 ] noreverse nowriteback ; set yrange [ 300 : 2000 ] noreverse nowriteback; set datafile separator ','; plot '$RESULTS/population$i.csv' using (column(\"food1\")):(column(\"food3\")); ; set title \"Food 2 - Food 3\"; unset key; set xlabel 'Food2'; set ylabel 'Food3';set datafile separator ','; set xrange [ 100 : 1300 ] noreverse nowriteback ; set yrange [ 300 : 2000 ] noreverse nowriteback; set datafile separator ','; plot '$RESULTS/population$i.csv' using (column(\"food2\")):(column(\"food3\"));  set title \"zoom Food 1 - Food 3\"; unset key; set xlabel 'Food1'; set ylabel 'Food3';set datafile separator ','; set xrange [ 150 : 300 ] noreverse nowriteback ; set yrange [ 300 : 1500 ] noreverse nowriteback; set datafile separator ','; plot '$RESULTS/population$i.csv' using (column(\"food1\")):(column(\"food3\")); set title \" zoom Food 2 - Food 3\"; unset key; set xlabel 'Food2'; set ylabel 'Food3';set datafile separator ','; set xrange [ 250 : 600 ] noreverse nowriteback ; set yrange [ 300 : 1500 ] noreverse nowriteback; set datafile separator ','; plot '$RESULTS/population$i.csv' using (column(\"food2\")):(column(\"food3\"));unset multiplot" > $OUT/pic$i.jpeg
done

avconv  -i $OUT/pic%d.jpeg -r 50 replications.webm

