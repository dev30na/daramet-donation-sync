#!/usr/bin/env bash
# Installer for Daramet donation sync by dev30na
set -euo pipefail

# Detect server public IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Detected server IP: $SERVER_IP"

# Prompt for installation directory
read -p "Enter installation directory (default: /var/www/html/pay): " DEST_DIR
DEST_DIR=${DEST_DIR:-/var/www/html/pay}

# Prompt for API token
read -p "Enter Daramet API token: " API_TOKEN

# Prompt for database connection details
echo "\n=== Database Connection Settings ==="
read -p "Enter DB host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}
read -p "Enter DB user (default: root): " DB_USER
DB_USER=${DB_USER:-root}
read -s -p "Enter DB password: " DB_PASS
echo
read -p "Enter DB name (default: wizwiz): " DB_NAME
DB_NAME=${DB_NAME:-wizwiz}

# Prompt for user wallet table/columns
echo "\n=== Wallet Update Settings ==="
read -p "Enter the database table for users (default: users): " USER_TABLE
USER_TABLE=${USER_TABLE:-users}
read -p "Enter the wallet column name (default: wallet): " WALLET_COLUMN
WALLET_COLUMN=${WALLET_COLUMN:-wallet}
read -p "Enter the user ID column name (default: userid): " USER_ID_COLUMN
USER_ID_COLUMN=${USER_ID_COLUMN:-userid}

# Source URL for PHP script
FILE_URL="https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/web-daramet.php"

# Create install directory
if [ ! -d "$DEST_DIR" ]; then
  echo "Creating directory $DEST_DIR..."
  mkdir -p "$DEST_DIR"
fi

# Download PHP script
echo "Downloading web-daramet.php from GitHub..."
curl -sSL "$FILE_URL" -o "$DEST_DIR/web-daramet.php"

# Function to replace and verify
replace_and_verify() {
  local pattern="$1" repl="$2" file="$3"
  sed -i "$pattern" "$file"
  grep -q "$2" "$file" || { echo "Error replacing $1" >&2; exit 1; }
}

# Inject configuration into the PHP file
echo "Configuring web-daramet.php..."
PHP_FILE="$DEST_DIR/web-daramet.php"
replace_and_verify "s|^\\$allowedIp = .*;|\$allowedIp = '$SERVER_IP';|" "\$allowedIp = '$SERVER_IP';" "$PHP_FILE"
replace_and_verify "s|^\\$apiToken = .*;|\$apiToken = '${API_TOKEN}';|" "\$apiToken = '${API_TOKEN}';" "$PHP_FILE"
replace_and_verify "s|^\\$dbHost = .*;|\$dbHost = '${DB_HOST}';|" "\$dbHost = '${DB_HOST}';" "$PHP_FILE"
replace_and_verify "s|^\\$dbUser = .*;|\$dbUser = '${DB_USER}';|" "\$dbUser = '${DB_USER}';" "$PHP_FILE"
replace_and_verify "s|^\\$dbPass = .*;|\$dbPass = '${DB_PASS}';|" "\$dbPass = '${DB_PASS}';" "$PHP_FILE"
replace_and_verify "s|^\\$dbName = .*;|\$dbName = '${DB_NAME}';|" "\$dbName = '${DB_NAME}';" "$PHP_FILE"
replace_and_verify "s|^\\$userTable = .*;|\$userTable = '${USER_TABLE}';|" "\$userTable = '${USER_TABLE}';" "$PHP_FILE"
replace_and_verify "s|^\\$walletColumn = .*;|\$walletColumn = '${WALLET_COLUMN}';|" "\$walletColumn = '${WALLET_COLUMN}';" "$PHP_FILE"
replace_and_verify "s|^\\$userIdColumn = .*;|\$userIdColumn = '${USER_ID_COLUMN}';|" "\$userIdColumn = '${USER_ID_COLUMN}';" "$PHP_FILE"

# Set permissions for directory and script
echo "Setting ownership to www-data and permissions..."
chown -R www-data:www-data "$DEST_DIR"
chmod 755 "$DEST_DIR"
chmod 644 "$PHP_FILE"

# Install cron job every 5 minutes
echo "Setting up cron job..."
CRON_ENTRY="*/5 * * * * www-data php $PHP_FILE"
(crontab -u www-data -l 2>/dev/null | grep -v -F "$PHP_FILE"; echo "$CRON_ENTRY") | crontab -u www-data -

echo "\nInstallation complete."
echo "✔ Script located at $PHP_FILE"
echo "✔ Cron job added: $CRON_ENTRY"
echo "Coded BY dev30na with <3"
