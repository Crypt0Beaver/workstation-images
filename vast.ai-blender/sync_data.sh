#!/bin/bash
REMOTE_PATH="cloudstorage:vast-backups"
LOCAL_PATH="/root/work"

case "$1" in
    pull)
        rclone sync $REMOTE_PATH $LOCAL_PATH --progress ;;
    push)
        rclone sync $LOCAL_PATH $REMOTE_PATH --progress ;;
    daemon)
        while true; do
            sleep 300
            rclone sync $LOCAL_PATH $REMOTE_PATH
            echo "Cloud sync completed at $(date)"
        done ;;
esac
