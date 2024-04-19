#!/bin/bash

discordEpoch=1420070400000
workerId=0
processId=0
increment=0

# Get the name of a discord given a Guild Id
discord::getDiscordName() {
    url="https://discord.com/api/v9/guilds/${1}/preview"
    discordName=""

    while [[ -z "$discordName" ]]
    do
        discordName=$(curl -s -H curl -s -H "Authorization: ${TOKEN}" -H "Accept: application/json" $url \
            | python3 -m json.tool \
            | grep 'name' \
            | head -n 1 \
            | cut -d":" -f 2 \
            | sed -e 's/,//' -e 's/"//g'
        )
    done

    echo $discordName
}

discord::getChannelName() {
    url="https://discord.com/api/v9/channels/${1}"
    channelName=""

    while [[ -z "$channelName" ]]
    do
        channelName=$(curl -s -H curl -s -H "Authorization: ${TOKEN}" -H "Accept: application/json" $url \
            | python3 -m json.tool \
            | grep 'name' \
            | head -n 1 \
            | cut -d":" -f 2 \
            | sed -e 's/,//' -e 's/"//g'
        )
    done

    echo $channelName
}

# Discord snowflake generator (given timestamp)
discord::timestampToSnowflake() {
    elapsed=$(($1 * 1000 - $discordEpoch))

    snowflake=$(($elapsed << 22 | workerId << 17 | processId << 12 | increment))
    increment=$(((increment + 1) & 0xFFF))

    echo $snowflake
}