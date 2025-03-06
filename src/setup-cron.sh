#!/bin/bash

# Get the backup schedule from the environment variable
backup_schedule="$BACKUP_SCHEDULE"
project_dir="$PROJECT_DIR"

# Set the cron schedule based on the environment variable
case $backup_schedule in
    "daily") cron_schedule="0 0 * * *" ;; # Daily at midnight
    "every_2_days") cron_schedule="0 0 */2 * *" ;; # Every 2 days at midnight
    "weekly") cron_schedule="0 0 * * 0" ;; # Weekly on Sunday at midnight
    "monthly") cron_schedule="0 0 1 * *" ;; # Monthly on the 1st of each month at midnight
    *) echo "❌ Invalid schedule! Exiting."; exit 1 ;;
esac

echo "🔄 Setting up cron job with schedule: $cron_schedule for $project_dir"

# Create the cron job to run the backup
cron_job="cd $project_dir && ./backup.sh backup"
(crontab -l 2>/dev/null; echo "$cron_schedule $cron_job") | crontab -

# Start cron service in the background
cron && tail -f /dev/null
