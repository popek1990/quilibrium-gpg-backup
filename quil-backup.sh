#!/bin/bash

LOG_FILE="$HOME/backup.log"
echo "Backup started at $(date)" >> "$LOG_FILE"

# Redirect all output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

REQUIRED_CMDS=("rclone" "gpg" "tar")
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done

set -euo pipefail
trap 'rm -f "$BACKUP_FILE" "$ENCRYPTED_BACKUP_FILE"' EXIT

############################################
# USER CONFIGURATION - EDIT THESE VARIABLES
############################################

# Base directory where the items to backup are located
BASE_DIR="$HOME/ceremonyclient/node/.config"  # <-- Change this to your base directory

# Items to backup (relative to BASE_DIR)
BACKUP_ITEMS=("store" "keys.yml" "config.yml")     # <-- Add or remove items as needed

# Your GPG key IDs (public keys of recipients)
GPG_KEYS=("YOUR_GPG_KEY_ID_HERE")  # <-- Replace with your GPG key IDs

# Name of the remote connection in rclone
REMOTE_NAME="quil-onedrive"  # <-- Set your rclone remote name

# Path to the folder on OneDrive
REMOTE_DIR="quil-backup/1"  # <-- Set the remote directory path

############################################
# END OF USER CONFIGURATION
############################################

# Check if GPG keys are available
for key in "${GPG_KEYS[@]}"; do
  if ! gpg --list-keys "$key" >/dev/null 2>&1; then
    echo "Error: GPG key $key not found in keyring." >&2
    exit 1
  fi
done

# Check if the base directory exists
if [ ! -d "$BASE_DIR" ]; then
  echo "Base directory $BASE_DIR does not exist."
  exit 1
fi

# Generate date and time for filenames
CURRENT_DATE=$(date +'%Y-%m-%d')
CURRENT_TIME=$(date +'%H-%M')

# Path to the backup archive file (with date and time)
BACKUP_FILE="/tmp/backup_${CURRENT_DATE}_${CURRENT_TIME}.tar.gz"

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

# Remove the local backup files
rm -f "$BACKUP_FILE" "$ENCRYPTED_BACKUP_FILE"

echo "Backup finished at $(date)" >> "$LOG_FILE"

#############################################################################################
### A Bash script for encrypted backups to OneDrive using rclone and GPG by popek1990.eth ###
#############################################################################################

