#!/bin/bash
# ==========================================
# AUTOMATED BACKUP SCRIPT FOR BLUEFIN DX
# (VIP Client ID + Turbo Mode via ENV Vars)
# ==========================================

# 1. Master Repository & Password
export RESTIC_REPOSITORY="rclone:gdrive_backup:Bluefin_Backups"
export RESTIC_PASSWORD="YOUR_RESTIC_PASSWORD_HERE"

# 2. Turbo API Injection (High Concurrency)
export RCLONE_TRANSFERS=16
export RCLONE_CHECKERS=16
export RCLONE_DRIVE_CHUNK_SIZE="64M"

# 3. Target Paths
EXCLUDE_FILE="$HOME/.backup_exclude.txt"
TARGET_DIR="$HOME"

# 4. Telegram Notification Credentials
BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN_HERE"
CHAT_ID="YOUR_TELEGRAM_CHAT_ID_HERE"

send_notif() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="${message}" > /dev/null
}

send_notif "⏳ [START] Initiating Turbo Backup for ${USER} on Bluefin DX..."

# 5. Execution & GFS Pruning
if restic backup "$TARGET_DIR" --exclude-file="$EXCLUDE_FILE" --verbose; then
    
    restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
    send_notif "✅ [SUCCESS] Turbo Backup completed! Data is safely secured in Google Drive."
else
    send_notif "❌ [FAILED] Backup error detected. Check local system logs."
fi
