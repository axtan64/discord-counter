#!/bin/bash

# Function to display a progress bar
progressBar::show() {
    BAR_SIZE=40

    complete=$((($BAR_SIZE * $1) / 100))
    todo=$((($BAR_SIZE - $complete)))
    done_sub_bar=$(printf "%${complete}s" | tr " " "#")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "-")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${1}%"
}