# Use an official Ubuntu as a parent image
FROM ubuntu:20.04

# Set environment variables for non-interactive setup
ENV DEBIAN_FRONTEND=noninteractive

# Set the timezone
ENV TZ=Asia/Colombo

# Install required packages (cron, bash, and any other dependencies)
RUN apt-get update && \
    apt-get install -y \
    mysql-client \
    cron \
    bash \
    nano \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /opt/www

# Copy the backup script into the container
COPY ./src/backup.sh /opt/www/backup.sh
# COPY ./sample_env /opt/www/.env

# Make the backup script executable
RUN chmod +x /opt/www/backup.sh

# Add the cron job setup script
COPY ./src/setup-cron.sh /opt/www/setup-cron.sh
RUN chmod +x /opt/www/setup-cron.sh

# Add entrypoint to start cron and the main application
ENTRYPOINT ["bash", "/opt/www/setup-cron.sh"]
