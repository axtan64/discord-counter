#!/bin/bash

DAY_LENGTH=86400

tmpDailyMessages=results.csv
discordEpoch=1420070400000
workerId=0
processId=0
increment=0

# Source the config.txt file to access settings
. <(sed 's/\r$//' config.txt)

# Function to display a progress bar
progressBar() {
    BAR_SIZE=40

    complete=$((($BAR_SIZE * $1) / 100))
    todo=$((($BAR_SIZE - $complete)))
    done_sub_bar=$(printf "%${complete}s" | tr " " "#")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "-")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${1}%"
}

# Get UNIX timestamp from ISO8601 date
function isoToUnix() {
    timestamp=$(date +%s --date="$1")
    echo $timestamp
}

# Get DD/MM/YYYY date from UNIX timestamp
function unixToDate() {
    date=$(date -d "@$1" +'%d/%m/%Y')
    echo $date
}

# Discord snowflake generator (given timestamp)
function timestampToSnowflake() {
    elapsed=$(($1 * 1000 - $discordEpoch))

    snowflake=$(($elapsed << 22 | workerId << 17 | processId << 12 | increment))
    increment=$(((increment + 1) & 0xFFF))

    echo $snowflake
}

# Convert DD/MM/YYYY into ISO8601 format
function dateToIso() {
    day=$(echo $1 | sed -e 's/\/.*//')
    month=$(echo $1 | sed -e 's/^[0-9]*//' -e 's/\r$//' -e 's/[0-9]*$//' -e 's/\///g')
    year=$(echo $1 | sed -e 's/.*\///')
    echo "${year}-${month}-${day}T00:00:00+00:00"
}

# Get the name of a discord given a Guild Id
function getDiscordName() {
    previewUrl="https://discord.com/api/v9/guilds/${GUILD_ID}/preview"
    discordName=""

    while [[ -z "$discordName" ]]
    do
        discordName=$(curl -s -H curl -s -H "Authorization: ${TOKEN}" -H "Accept: application/json" $previewUrl \
            | python3 -m json.tool \
            | grep 'name' \
            | head -n 1 \
            | cut -d":" -f 2 \
            | sed -e 's/,//' -e 's/"//g'
        )
    done

    echo $discordName
}

echo 'Date,Messages' > $tmpDailyMessages

# Setup variables
discordName=$(getDiscordName)
lbISO=$(dateToIso $START_DATE)
ubISO=$(dateToIso $END_DATE)
lbTimestamp=$(isoToUnix $lbISO)
ubTimestamp=$(isoToUnix $ubISO)
numDays=$(((ubTimestamp - lbTimestamp) / DAY_LENGTH + 1))

# Get the number of messages between two dates
echo "Fetching messages in ${discordName}"
timestamp=$lbTimestamp
subUrl="https://discord.com/api/v9/guilds/${GUILD_ID}/messages/search?"
[[ ! -z "$CHANNEL_ID" ]] && subUrl="${subUrl}channel_id=${CHANNEL_ID}&"

while [ "$timestamp" -le "$ubTimestamp" ]
do 
    lbSnowflake=$(timestampToSnowflake $timestamp)
    nextTimestamp=$(($timestamp + DAY_LENGTH))
    ubSnowflake=$(timestampToSnowflake $nextTimestamp)
    date=$(unixToDate $timestamp)

    url="${subUrl}&min_id=${lbSnowflake}&max_id=${ubSnowflake}"
    numMessages=$(curl -s -H "Authorization: ${TOKEN}" -H "Accept: application/json" $url \
        | python3 -m json.tool \
        | grep 'total_results' \
        | cut -d":" -f 2 \
        | sed -e 's/,//' -e 's/ //'
    )
    percentage=$(awk '{ print ($1-$2)/($3-$2)*100 }' <<< "${timestamp} ${lbTimestamp} ${ubTimestamp}" | sed 's/\..*//' )
    progressBar $percentage
    [[ ! -z "$numMessages" ]] && echo "${date},${numMessages}" >> $tmpDailyMessages && timestamp=$((timestamp + DAY_LENGTH)) && sleep 1
done

# Plot CSV on a graph
gnuplot -persist <<-EOFMarker
    set title "Discord Messages Each Day (${discordName})"
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
    plot "$tmpDailyMessages" using 1:2 title 'Messages' w l lw 2
EOFMarker

echo -e "\nFinished Scanning and Plotting ${numDays} days"