#!/bin/bash

# Configuration
REMOTE_NAME="mycloud"  # The name you gave your rclone remote
REMOTE_PATH="vast_backups/project1"
LOCAL_PATH="/root/cloud_sync"

case "$1" in
    pull)
        echo "Pulling latest data from cloud..."
        rclone sync $REMOTE_NAME:$REMOTE_PATH $LOCAL_PATH --progress
        ;;
    push)
        echo "Pushing data to cloud..."
        rclone sync $LOCAL_PATH $REMOTE_NAME:$REMOTE_PATH --progress
        ;;
    *)
        echo "Usage: $0 {pull|push}"
        ;;
esac
