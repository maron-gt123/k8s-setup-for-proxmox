#!/bin/bash

# region : set variables

WAIT=60
STARTSCRIPT=/minecraft/paper/mic-start.sh
SCREEN_NAME='paper'
MINECRAFT_WORLD=/minecraft/paper
HOSTNAME=`hostname`

# endregion

# ---

# region : stop minecraft

# world messsage
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "say '${WAIT}'秒後にサーバーを停止し、バックアップ作業 に入ります\015"'
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "say 10分後に再接続可能になるので、しばらくお待ち下さい\015"'


# minecraft stop cmd
sleep $WAIT
screen -p 0 -S ${SCREEN_NAME} -X eval 'stuff "stop\015"'

# ---
# minecraft restart
$STARTSCRIPT

# ---
