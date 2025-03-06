#!/bin/bash

# Function to check and install dependencies
install_dependencies() {
    echo "🔄 Checking and installing dependencies..."

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "❌ git is not installed. Installing..."
        sudo apt update && sudo apt install -y git
    fi

}

# Clone the repository if it doesn't exist
clone_repo() {
    local project_dir="$1"
    echo "🔄 Cloning the repository into $project_dir..."

    if [ ! -d "$project_dir" ]; then
        git clone https://github.com/NoobLk/BackUpify.git "$project_dir"
    else
        echo "✅ Repository already exists in $project_dir. Pulling latest changes..."
        cd "$project_dir" && git pull origin main && cd ..
    fi
}

# Rename .env_sample to .env
rename_env_file() {
    local project_dir="$1"
    echo "🔄 Renaming .env_sample to .env in $project_dir..."

    if [ -f "$project_dir/.env_sample" ]; then
        cp "$project_dir/.env_sample" "$project_dir/.env"
    else
        echo "❌ .env_sample file not found in $project_dir!"
        exit 1
    fi
}

# Install required PHP/Node dependencies
install_php_dependencies() {
    local project_dir="$1"
    echo "🔄 Installing PHP dependencies in $project_dir..."
    cd "$project_dir" && composer install && cd ..
}

install_node_dependencies() {
    local project_dir="$1"
    echo "🔄 Installing Node.js dependencies in $project_dir..."
    cd "$project_dir" && npm install && cd ..
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

    install_dependencies
    clone_repo "$project_dir"
    rename_env_file "$project_dir"
    install_php_dependencies "$project_dir"
    install_node_dependencies "$project_dir"
    schedule_backup "$project_dir"
}

# Ensure the script runs for both directories (auto-detect current path)
current_directory=$(pwd)

echo "🔄 Installing and setting up Project 1 in $current_directory..."
install_process "$current_directory"

echo "🎉 Installation and setup completed successfully for $current_directory!"
