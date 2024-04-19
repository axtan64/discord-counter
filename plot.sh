#!/bin/bash

# Source modules

source "./modules/date.sh"

# Initialise Variables
results=$1
title=$2
lbTimestamp=$(head -n 2 $results | tail -n 1 | cut -d',' -f 1)
ubTimestamp=$(tail -n 1 $results | cut -d',' -f 1)
lbTimestamp=$(date::dateToIso $lbTimestamp)
ubTimestamp=$(date::dateToIso $ubTimestamp)
lbTimestamp=$(date::isoToUnix $lbTimestamp)
ubTimestamp=$(date::isoToUnix $ubTimestamp)
numPoints=$(tail -n +2 $results | wc -l)
spanDays=$(((ubTimestamp - lbTimestamp) / DAY_LENGTH + 1))

# Plot CSV on a graph
gnuplot -persist <<-EOFMarker
    set title "$title"
    set key top left
    set grid
    set datafile separator ","
    set format x '%d/%m/%Y'
    set timefmt "%d/%m/%Y"
    set xdata time
    set xtics mirror rotate by -90
    set xlabel 'Date'
    set ylabel 'Messages'
    set term png
    set terminal png size 1368,768
    set output "messages.png"
    plot "$results" using 1:2 title 'Messages' w l lw 2
EOFMarker

echo -e "\nFinished Scanning and Plotting ${numPoints} data points"