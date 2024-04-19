#!/bin/bash

# Source the config.txt file to access settings
. <(sed 's/\r$//' config.txt)

# Source modules
source "./modules/discord.sh"
source "./modules/progressBar.sh"
source "./modules/date.sh"

# Set CSV headers
tmpDailyMessages=results.csv
echo 'Date,Messages' > $tmpDailyMessages

# Initialise variables
discordName=$(discord::getDiscordName $GUILD_ID | sed 's/\\u....//g')
channelName="${CHANNEL_ID:+"#$(discord::getChannelName $CHANNEL_ID | sed 's/\\u....//g')"}"
lbISO=$(date::dateToIso $START_DATE)
ubISO=$(date::dateToIso $END_DATE)
lbTimestamp=$(date::isoToUnix $lbISO)
ubTimestamp=$(date::isoToUnix $ubISO)
pauseTime=$(awk '{ print ($1/1000) }' <<< ${PAUSE_MILLIS:-1000})
interval=$(($DAY_LENGTH * ${DAY_INTERVAL:-1}))

# Get the number of messages between two dates
echo "Fetching messages in ${discordName}${channelName:+" (${channelName})"}"
timestamp=$lbTimestamp
subUrl="https://discord.com/api/v9/guilds/${GUILD_ID}/messages/search?${CHANNEL_ID:+"channel_id=${CHANNEL_ID}&"}"

progressBar::show 0
while [ "$timestamp" -le "$ubTimestamp" ]
do 
    nextTimestamp=$(($timestamp + $interval))
    lbSnowflake=$(discord::timestampToSnowflake $timestamp)
    ubSnowflake=$(discord::timestampToSnowflake $nextTimestamp)
    date=$(date::unixToDate $timestamp)

    url="${subUrl}&min_id=${lbSnowflake}&max_id=${ubSnowflake}"
    numMessages=$(curl -s -H "Authorization: ${TOKEN}" -H "Accept: application/json" $url \
        | python3 -m json.tool \
        | grep 'total_results' \
        | cut -d":" -f 2 \
        | sed -e 's/,//' -e 's/ //'
    )
    percentage=$(awk '{ print ($1-$2)/($3-$2)*100 }' <<< "${timestamp} ${lbTimestamp} ${ubTimestamp}" | sed 's/\..*//' )
    progressBar::show $percentage
    [[ ! -z "$numMessages" ]] && echo "${date},${numMessages}" >> $tmpDailyMessages && timestamp=$nextTimestamp && sleep $pauseTime
done
progressBar::show 100

/bin/bash plot.sh $tmpDailyMessages "Discord Messages Each Day (${discordName})${channelName:+" (${channelName})"}"