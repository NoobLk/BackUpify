#!/bin/bash

# Function to set the system timezone to Asia/Colombo
set_timezone() {
    echo "🌍 Setting the system timezone to Asia/Colombo..."
    sudo timedatectl set-timezone Asia/Colombo
    echo "✅ Timezone set to Asia/Colombo."
}

# Ask user for backup schedule and configure cron job
schedule_backup() {
    local project_dir="$1"

    echo "🕒 Please choose the backup schedule for $project_dir:"
    echo "1) Daily"
    echo "2) Every 2 days"
    echo "3) Weekly"
    echo "4) Monthly"
    read -p "Enter the number corresponding to your schedule: " schedule_choice

    # Define the cron schedule based on user input
    case $schedule_choice in
        1) cron_schedule="0 0 * * *" ;; # Daily at midnight
        2) cron_schedule="0 0 */2 * *" ;; # Every 2 days at midnight
        3) cron_schedule="0 0 * * 0" ;; # Weekly on Sunday at midnight
        4) cron_schedule="0 0 1 * *" ;; # Monthly on the 1st of each month at midnight
        *) echo "❌ Invalid option! Exiting."; exit 1 ;;
    esac

    echo "🔄 Setting up cron job with schedule: $cron_schedule for $project_dir"

    # Check if cron job exists and update it, or create a new one
    cron_job="cd $project_dir && ./backup.sh backup"
    crontab -l | grep -v "$cron_job" > mycron
    echo "$cron_schedule $cron_job" >> mycron
    crontab mycron
    rm mycron

    echo "✅ Cron job has been set successfully for $project_dir."
}

# Main installation process
install_process() {
    local project_dir="$1"
    set_timezone    # Call the function to set the timezone
    schedule_backup "$project_dir"
}

# Ensure the script runs for both directories (auto-detect current path)
current_directory=$(pwd)

echo "🔄 Installing and setting up Project 1 in $current_directory..."
install_process "$current_directory"

echo "🎉 Installation and setup completed successfully for $current_directory!"
