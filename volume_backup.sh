#!/bin/bash
# This script allows you to backup a single volume from a container
# Data in given volume is saved in the current directory in a tar archive.
CONTAINER_NAME=$1
VOLUME_NAME=$2

usage() {
  echo "Usage: $0 [container name] [volume name]"
  exit 1
}

if [ -z $CONTAINER_NAME ]
then
  echo "Error: missing container name parameter."
  usage
fi

if [ -z $VOLUME_NAME ]
then
  echo "Error: missing volume name parameter."
  usage
fi

sudo docker run --rm --volumes-from $CONTAINER_NAME -v $(pwd):/backup busybox tar cvf /backup/backup.tar $VOLUME_NAME


## Instruction
## $ volume_backup.sh old_container /srv/www
## $ sudo docker stop old_container && sudo docker rm old_container
## $ sudo docker run -d --name new_container myrepo/new_container
## $ volume_restore.sh new_container