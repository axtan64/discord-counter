#!/bin/bash

DAY_LENGTH=86400

# Get DD/MM/YYYY date from UNIX timestamp
date::unixToDate() {
    date=$(date -d "@$1" +'%d/%m/%Y')
    echo $date
}

# Get UNIX timestamp from ISO8601 date
date::isoToUnix() {
    timestamp=$(date +%s --date="$1")
    echo $timestamp
}

# Convert DD/MM/YYYY into ISO8601 format
date::dateToIso() {
    day=$(echo $1 | sed -e 's/\/.*//')
    month=$(echo $1 | sed -e 's/^[0-9]*//' -e 's/\r$//' -e 's/[0-9]*$//' -e 's/\///g')
    year=$(echo $1 | sed -e 's/.*\///')
    echo "${year}-${month}-${day}T00:00:00+00:00"
}