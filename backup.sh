#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Get current timestamp
timestamp=$(date +%Y_%m_%d_%H:%M:%S)
backup_dir="./backups/$SITE_NAME/"
folderststus_fail_message="Warning: Site source directory is either missing or empty. Backup Not Going to Continue"
dbststus_fail_message="MySQL Access not Working. Backup Not Going to Continue"



function environment_check() {
    # Define failure messages (optional, if not already defined)
    folderststus_fail_message="Backup failed: WordPress directory is missing or empty."
    mysqlststus_fail_message="Backup failed: MySQL is not accessible. in site "

    # Check if MySQL is running
    if mysqladmin -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" ping &>/dev/null; then
        echo "MySQL Access Working, proceeding with backup."
        dbststus="ok"
    else
        dbststus="false"
        # Send notification via Telegram
        for CHAT_ID in "${CHAT_IDS[@]}"; do
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&parse_mode=Markdown&text=$mysqlststus_fail_message in site = $SITE_NAME"
        done
        echo "MySQL Access not Working. Backup Not Going to Continue."
        return 1  # Exit the function if MySQL is not accessible
    fi

    # Check if WP_DIR exists and is not empty
    if [ -d "$WP_DIR" ] && [ "$(ls -A "$WP_DIR")" ]; then
        echo "WordPress directory $WP_DIR is present and not empty."
        folderststus="ok"
    else
        echo "Warning: WordPress directory $WP_DIR is either missing or empty."
        folderststus="false"
        # Send notification via Telegram
        for CHAT_ID in "${CHAT_IDS[@]}"; do
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&parse_mode=Markdown&text=$folderststus_fail_message in site = $SITE_NAME"
        done
        return 1  # Exit the function if WP_DIR is invalid
    fi
}


function run_backup() {
    # Check environment status
    environment_check

    # Check if dbststus is 'ok'
    if [ "$dbststus" == "ok" ] && [ "$folderststus" == "ok" ]; then
        # Create backup directory with timestamp
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
    else
        echo "Backup Fail"
    fi
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

    send_notification
}

# Function to restore backup
restore_backup() {

    # Check environment status
    environment_check

    # Check if both dbststus and folderststus are 'ok'
    if [ "$dbststus" == "ok" ] && [ "$folderststus" == "ok" ]; then

        if [ -z "$1" ]; then
            echo "Usage: $0 restore <YYYY-MM-DD_HH-MM-SS>"
            exit 1
        fi

        BACKUP_PATH="$backup_dir/$1"

        if [ ! -d "$BACKUP_PATH" ]; then
            echo "Backup not found: $BACKUP_PATH"
            exit 1
        fi

        echo "Restoring backup from $BACKUP_PATH..."

        # Check if backup files exist
        if [ ! -f "$BACKUP_PATH/wp_files.tar.gz" ]; then
            echo "WordPress file backup not found: $BACKUP_PATH/wp_files.tar.gz"
            exit 1
        fi

        if [ ! -f "$BACKUP_PATH/db.sql" ]; then
            echo "Database backup not found: $BACKUP_PATH/db.sql"
            exit 1
        fi

        # Restore WordPress files
        echo "Restoring WordPress files..."
        tar -xzf "$BACKUP_PATH/wp_files.tar.gz" -C "$WP_DIR" --strip-components=1
        if [ $? -ne 0 ]; then
            echo "Failed to restore WordPress files."
            exit 1
        fi

        # Drop and recreate the database
        echo "Restoring MySQL database..."
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"
        if [ $? -ne 0 ]; then
            echo "Failed to drop and recreate the database."
            exit 1
        fi

        # Restore MySQL database
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$BACKUP_PATH/db.sql"
        if [ $? -ne 0 ]; then
            echo "Failed to restore the database."
            exit 1
        fi

        echo "Restore completed successfully."

    else
        echo "Restore Fail"
    fi
}



list_backups() {
    echo "Listing current backups for $SITE_NAME..."
    BACKUPS=($(ls -dt "$backup_dir"/*))
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo "No backups found."
    else
        for BACKUP in "${BACKUPS[@]}"; do
            echo "$(basename "$BACKUP")"
        done
    fi
}

send_notification() {
    if [[ "$INCLUDE_DB" == "yes" ]]; then
        db_backup_state='✅ Yes'
    else
        db_backup_state='❌ No'
    fi

    MESSAGE="*======= Backup Notification =======* 

🔹 *Backup Site Name*: \`$SITE_NAME\`
🔹 *Database Backup*: $db_backup_state
🔹 *Backup Path*: \`$backup_dir\`
🔹 *Backup Time Stamp*: \`$timestamp\`
🔹 *Max Backups Allowd*: \`$MAX_BACKUPS\`

*🔔 Backup Completed Successfully!*"

    for CHAT_ID in "${CHAT_IDS[@]}"
    do
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID&parse_mode=Markdown&text=$MESSAGE"
    done
}




# Check if the script was called with an argument
if [ "$1" == "backup" ]; then
    run_backup
elif [ "$1" == "restore" ]; then
    restore_backup "$2"
elif [ "$1" == "list" ]; then
    list_backups
else
    echo "No valid command provided. Use './backup.sh backup' to run the backup or './backup.sh restore <timestamp>' to restore a backup."
fi


