![image](https://github.com/user-attachments/assets/55865df4-9eb7-4924-bb72-a8f23702a2da)


**###   Install Required Tools    ###**

`sudo apt update`

`curl https://rclone.org/install.sh | sudo bash`

`sudo apt install gnupg`

`sudo apt install pigz`

`sudo apt install git`


**###   Configure rclone with OneDrive   ###**

**Start rclone configuration:**

`rclone config`

- Type `n` to create a new remote connection.
- Enter a name for the remote connection, e.g `quil-backup1`.
- From the list of storage types, choose your cloud provider. I used `onedrive`.
- Press Enter to accept the default settings or adjust them as needed.
- When prompted for authorization, rclone will open a web browser. Log in to your Microsoft account and allow access.
- After successful authorization, the configuration will be saved.

**Test the connection:**

`rclone lsd quil-ondrive:`   #quil-ondrive = yours rclone remote connection name

_You should see a list of your OneDrive folders._

**###   Download the backup script   ###**

`git clone https://github.com/yourusername/backup-script.git`

`cd quilibrium-gpg-backup`

`chmod +x quil-backup.sh`

**###   Create or import GPG keys   ###**

`gpg --import recipient_public_key.asc` or `gpg --full-generate-key`

`gpg --list-keys`

**###   Edit the script configuration   ###**

`nano quil-backup.sh`

At the top of the script, you will find the USER CONFIGURATION section. Update the following variables:

```############################################
# USER CONFIGURATION - EDIT THESE VARIABLES
############################################

# Base directory where the items to backup are located
BASE_DIR="/home/user/ceremonyclient/node/.config"  # <-- Change this to your base directory

# Your GPG key IDs (public keys of recipients)
GPG_KEYS=("YOUR_GPG_KEY_ID")  # <-- Replace with your GPG key IDs

# Name of the remote connection in rclone
REMOTE_NAME="onedrive"  # <-- Set your rclone remote name (`rclone listremotes`)

# Path to the folder on OneDrive
REMOTE_DIR="backup-folder"  # <-- Set the remote directory path

############################################
# END OF USER CONFIGURATION
############################################
```
`BASE_DIR:` Change this to the directory containing the files you want to back up.

`GPG_KEYS:` Replace `YOUR_GPG_KEY_ID` with your GPG key ID(s).

`REMOTE_NAME:` Set this to the name you chose when configuring rclone (e.g., "onedrive").

`REMOTE_DIR:` Set the path on OneDrive where you want to store the backups.

**###   Run the backup script   ###**

`./quil-backup.sh`

**### Automate the Backup (Optional) ###**

**Edit the crontab:**
`crontab -e`

**Add the following line:**

`0 2 * * * /path/to/backup.sh >> /var/log/backup.log 2>&1`

_Replace `/path/to/backup.sh` with the actual path to your backup script._

**Notes:**

- Ensure that your GPG keys are properly managed and secured.
- The script uses pigz for faster compression. If not installed, it will use gzip.
- The backup file is named with the current date: backup_YYYY-MM-DD.tar.gz.gpg


By [popek1990.eth]([url](https://x.com/popek_1990))

![image](https://github.com/user-attachments/assets/88d77576-6bcb-4877-b603-e067f2da81dd)






