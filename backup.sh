#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Get current timestamp
timestamp=$(date +%Y_%m_%d_%H:%M:%S)
backup_path="./backups/$SITE_NAME/$timestamp"
backup_path2="./backups/$SITE_NAME/"

function run_backup() {
    mkdir -p "$backup_path"

    Uncomment below to enable database backup
    echo "Backing up database..."
    if [[ "$INCLUDE_DB" == "yes" ]]; then
        mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$backup_path/db.sql"
    else
        echo "Database backup is disabled for this configuration."
    fi

    echo "Backing up $SITE_NAME files..."
    if [ -d "$WP_DIR" ]; then
        tar -czf "$backup_path/wp_files.tar.gz" -C "$WP_DIR" .
        echo "File backup successful."
    else
        echo "Warning: The WordPress directory does not exist: $WP_DIR"
    fi


    echo "Backup for $SITE_NAME completed at $backup_path"

    # Remove old backups if the number exceeds MAX_BACKUP_COUNT

    cleanup_backups
}

# Function to clean up old backups
cleanup_backups() {
    BACKUPS=($(ls -dt "$backup_path2"/*))
    if [ ${#BACKUPS[@]} -gt $MAX_BACKUPS ]; then
        for ((i = $MAX_BACKUPS; i < ${#BACKUPS[@]}; i++)); do
            echo "Deleting old backup: ${BACKUPS[$i]}"
            rm -rf "${BACKUPS[$i]}"
        done
    fi
}


# Check if the script was called with an argument
if [ "$1" == "backup" ]; then
    run_backup
else
    echo "No valid command provided. Use './backup.sh backup' to run the backup."
fi

echo "Operation timestamp: $timestamp"
