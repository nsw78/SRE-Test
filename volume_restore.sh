#!/bin/bash
# This script allows you to restore a single volume from a container
# Data in restored in volume with same backupped path
NEW_CONTAINER_NAME=$1

usage() {
  echo "Usage: $0 [container name]"
  exit 1
}

if [ -z $NEW_CONTAINER_NAME ]
then
  echo "Error: missing container name parameter."
  usage
fi

sudo docker run --rm --volumes-from $NEW_CONTAINER_NAME -v $(pwd):/backup busybox tar xvf /backup/backup.tar


## Instruction
## $ volume_backup.sh old_container /srv/www
## $ sudo docker stop old_container && sudo docker rm old_container
## $ sudo docker run -d --name new_container myrepo/new_container
## $ volume_restore.sh new_container