function run_backup() {
    # Check environment status
    environment_check

    # Check if both dbststus and folderststus are 'ok'
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
        echo "Backup conditions are not met. dbststus or folderststus is not 'ok'."
    fi
}
