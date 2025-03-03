from apscheduler.schedulers.background import BackgroundScheduler
import configparser
import subprocess
import os
from datetime import datetime

def install_dependencies():
    print("Installing required packages...")
    subprocess.run(["sudo", "apt-get", "install", "mysql-client", "-y"])
    print("Dependencies installed.")

def uninstall():
    print("Removing all backups and configurations...")
    os.system("sudo rm -rf /etc/backup_master/")
    print("Uninstallation complete.")

def run_backup(config_id):
    config = configparser.ConfigParser()
    config.read('backup_details.cfg')
    wp_dir = config.get(config_id, 'WP_DIR')
    db_name = config.get(config_id, 'DB_NAME')
    db_user = config.get(config_id, 'DB_USER')
    db_host = config.get(config_id, 'DB_HOST')
    db_port = config.get(config_id, 'DB_PORT')
    db_password = config.get(config_id, 'DB_PASSWORD')
    include_db = config.get(config_id, 'INCLUDE_DB') == 'yes'
    max_backups = config.getint(config_id, 'MAX_BACKUPS')

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = f"/etc/backup_master/{config_id}/{timestamp}"
    os.makedirs(backup_path, exist_ok=True)

    if include_db:
        print("Backing up database...")
        subprocess.run(f"mysqldump -h {db_host} -P {db_port} -u {db_user} -p{db_password} {db_name} > {backup_path}/db.sql", shell=True)

    print("Backing up WordPress files...")
    subprocess.run(f"tar -czf {backup_path}/wp_files.tar.gz -C {wp_dir} .", shell=True)
    print("File backup successful.")

    manage_old_backups(config_id, max_backups)

def manage_old_backups(config_id, max_backups):
    backup_dir = f"/etc/backup_master/{config_id}"
    backups = sorted([os.path.join(backup_dir, d) for d in os.listdir(backup_dir) if os.path.isdir(os.path.join(backup_dir, d))], reverse=True)
    for old_backup in backups[max_backups:]:
        os.system(f"rm -rf {old_backup}")

def list_configs():
    config = configparser.ConfigParser()
    config.read('backup_details.cfg')
    return config.sections()

def choose_config_and_backup():
    configs = list_configs()
    print("Available configurations:")
    for config in configs:
        print(config)
    config_id = input("Enter configuration ID: ")
    run_backup(config_id)

if __name__ == "__main__":
    print("WordPress Backup Manager")
    print("1) Install Dependencies")
    print("2) Run Backup Now")
    print("3) Uninstall")
    option = input("Select an option: ")

    if option == "1":
        install_dependencies()
    elif option == "2":
        choose_config_and_backup()
    elif option == "3":
        uninstall()
    else:
        print("Invalid option selected.")
