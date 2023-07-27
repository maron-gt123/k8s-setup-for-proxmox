#!/bin/bash

# region : set variables
JARFILE=/minecraft/paper/paper-*
MEM=2048M
SCREEN_NAME=paper
# endregion

# start minecraft
cd `dirname $0`
screen -AdmS ${SCREEN_NAME} java -server -Xms${MEM} -Xmx${MEM} -jar ${JARFILE} nogui

# time and water cycle is false
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "gamerule doDaylightCycle false\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "gamerule doWeatherCycle false\015"'

# time and water is set
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "time set day\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "weather clear\015"'

# ---end---
