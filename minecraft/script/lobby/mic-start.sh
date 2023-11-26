#!/bin/bash

# region : set variables
JARFILE=/minecraft/paper/paper-*
MINMEM=500M
MAXMEM=1024M
SCREEN_NAME=paper
# endregion

# start minecraft
cd `dirname $0`
screen -AdmS ${SCREEN_NAME} java -server -Xms${MINMEM} -Xmx${MAXMEM} -jar ${JARFILE} nogui

# sleep 60s
sleep 60s

# time and water cycle is false
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "gamerule doDaylightCycle false\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "gamerule doWeatherCycle false\015"'

# time and water is set
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "time set day\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "weather clear\015"'

# ---end---
