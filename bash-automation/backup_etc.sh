#!/bin/bash

SOURCE_DIR="/etc"
DEST_DIR="$HOME/haifa.work/backups"
LOG_FILE="$HOME/haifa.work/backups/backup_history.log"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="etc_backup_$TIMESTAMP.tar.gz"

mkdir -p "$DEST_DIR"

# Run backup and log the result
if sudo tar -czf "$DEST_DIR/$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null; then
    echo "[$TIMESTAMP] SUCCESS: Backup created." >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] ERROR: Backup failed." >> "$LOG_FILE"
fi

# Rotation: Keep only the last 7 days
find "$DEST_DIR" -name "*.tar.gz" -type f -mtime +7 -delete
