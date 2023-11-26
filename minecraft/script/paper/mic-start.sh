#!/bin/bash

# region : set variables
JARFILE=/minecraft/paper/paper-*
MINMEM=1024M
MAXMEM=2048M
SCREEN_NAME=paper
# endregion

# region : start minecraft
cd `dirname $0`
screen -AdmS ${SCREEN_NAME} java -server -Xms${MINMEM} -Xmx${MAXMEM} -jar ${JARFILE} nogui

# ---end---
