#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Get current timestamp
timestamp=$(date +%Y_%m_%d_%H:%M:%S)
backup_dir="./backups/$SITE_NAME/"


function run_backup() {
    mkdir -p "$backup_dir/$timestamp"

    echo "Backing up database..."
    if [[ "$INCLUDE_DB" == "yes" ]]; then

    # Backup MySQL database
        mysqldump -h "$DB_HOST" -P "$DB_PORT" --no-tablespaces -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$backup_dir/$timestamp/db.sql"
        echo "Database backup dir is = $backup_dir"
    else
        echo "Database backup is disabled for this configuration."
    fi

    echo "Backing up $SITE_NAME files..."
    if [ -d "$WP_DIR" ]; then
        tar -czf "$backup_dir/$timestamp/wp_files.tar.gz" -C "$WP_DIR" .
        echo "File backup successful."
    else
        echo "Warning: The WordPress directory does not exist: $WP_DIR"
    fi


    echo "Backup for $SITE_NAME completed at $backup_dir"

    # Remove old backups if the number exceeds MAX_BACKUP_COUNT

    cleanup_backups
}

# Function to clean up old backups
cleanup_backups() {
    BACKUPS=($(ls -dt "$backup_dir"/*))
    if [ ${#BACKUPS[@]} -gt $MAX_BACKUPS ]; then
        for ((i = $MAX_BACKUPS; i < ${#BACKUPS[@]}; i++)); do
            echo "Deleting old backup: ${BACKUPS[$i]}"
            rm -rf "${BACKUPS[$i]}"
        done
    fi
}



restore_backup() {
    if [ -z "$1" ]; then
        echo "Usage: $0 restore <YYYY-MM-DD_HH-MM-SS>"
        exit 1
    fi

    BACKUP_PATH="$BACKUP_DIR/backup_$1"

    if [ ! -d "$BACKUP_PATH" ]; then
        echo "Backup not found: $BACKUP_PATH"
        exit 1
    fi

    echo "Restoring backup from $BACKUP_PATH..."

    # Restore WordPress files
    tar -xzf "$BACKUP_PATH/wordpress_files.tar.gz" -C "$WORDPRESS_DIR" --strip-components=1

    # Drop and recreate the database
    docker exec -i $DB_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"

    # Restore MySQL database
    docker exec -i $DB_CONTAINER mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME < "$BACKUP_PATH/db_backup.sql"

    echo "Restore completed."
}


# Check if the script was called with an argument
if [ "$1" == "backup" ]; then
    run_backup
else
    echo "No valid command provided. Use './backup.sh backup' to run the backup."
fi

echo "Operation timestamp: $timestamp"
