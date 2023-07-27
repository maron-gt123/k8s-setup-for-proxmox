#!/bin/bash

# region : set variables
JARFILE=/minecraft/paper/paper-*
MEM=2048M
SCREEN_NAME=paper
# endregion

# region : start minecraft
cd `dirname $0`
screen -AdmS ${SCREEN_NAME} java -server -Xms${MEM} -Xmx${MEM} -jar ${JARFILE} nogui

# ---end---
