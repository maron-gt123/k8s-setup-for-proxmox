#!/bin/bash

# region : set variables
JARFILE=/minecraft/paper/paper-*
MEM=2048M
# endregion

# ---

# region : start minecraft
cd `dirname $0`
screen -AdmS paper java -server -Xms${MEM} -Xmx${MEM} -jar ${JARFILE} nogui
# ---
