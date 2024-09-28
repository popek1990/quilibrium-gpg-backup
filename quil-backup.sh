#!/bin/bash
set -euo pipefail
trap 'rm -f "$BACKUP_FILE" "$ENCRYPTED_BACKUP_FILE"' EXIT

############################################
# USER CONFIGURATION - EDIT THESE VARIABLES
############################################

# Base directory where the items to backup are located
BASE_DIR="/home/user/ceremonyclient/node/.config"  # <-- Change this to your base directory

# Items to backup (relative to BASE_DIR)
BACKUP_ITEMS=("store" "keys.yml" "config.yml")     # <-- Add or remove items as needed

# Your GPG key IDs (public keys of recipients)
GPG_KEYS=("9716963681F2BBD10414A4DB3AC3FCCE54124D1A")  # <-- Replace with your GPG key IDs

# Name of the remote connection in rclone
REMOTE_NAME="quil-onedrive"                               # <-- Set your rclone remote name

# Path to the folder on OneDrive
REMOTE_DIR="quil-backup/1"                           # <-- Set the remote directory path

############################################
# END OF USER CONFIGURATION
############################################

# Check if the base directory exists
if [ ! -d "$BASE_DIR" ]; then
  echo "Base directory $BASE_DIR does not exist."
  exit 1
fi

# Path to the backup archive file (with date)
BACKUP_FILE="/tmp/backup_$(date +'%Y-%m-%d').tar.gz"

# Encrypted backup file
ENCRYPTED_BACKUP_FILE="${BACKUP_FILE}.gpg"

# Function to build the list of GPG recipients
function build_gpg_recipients() {
  local recipients=()
  for key in "${GPG_KEYS[@]}"; do
    recipients+=("--recipient" "$key")
  done
  echo "${recipients[@]}"
}

echo "Creating archive..."

# Use pigz for multi-threaded compression (faster for large files)
if command -v pigz >/dev/null 2>&1; then
  tar -cf - -C "$BASE_DIR" "${BACKUP_ITEMS[@]}" | pigz > "$BACKUP_FILE"
else
  tar -czf "$BACKUP_FILE" -C "$BASE_DIR" "${BACKUP_ITEMS[@]}"
fi

echo "Encrypting archive..."
GPG_RECIPIENTS=($(build_gpg_recipients))
gpg --trust-model always --encrypt "${GPG_RECIPIENTS[@]}" --output "$ENCRYPTED_BACKUP_FILE" "$BACKUP_FILE"

echo "Uploading backup to OneDrive..."
if rclone copy "$ENCRYPTED_BACKUP_FILE" "$REMOTE_NAME:$REMOTE_DIR/" --onedrive-no-versions; then
  echo "Backup successfully uploaded."
else
  echo "Backup upload failed."
  exit 1
fi

#############################################################################################
### A Bash script for encrypted backups to OneDrive using rclone and GPG by popek1990.eth ###
#############################################################################################
