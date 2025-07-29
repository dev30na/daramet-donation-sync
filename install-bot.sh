#!/usr/bin/env bash
# Installer for bot-daramet.php by dev30na
set -euo pipefail

echo "🔧 Starting Bot Donation Sync Installer (dev30na)..."

# 1) inputs
read -p "Enter your Daramet API token: " TOKEN
read -p "Enter Telegram Bot Token: " BOT_TOKEN
read -p "Enter Admin Chat ID (numeric): " ADMIN_CHAT_ID
read -p "Enter MySQL host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}
read -p "Enter MySQL database name: " DB_NAME
read -p "Enter MySQL username: " DB_USER
read -s -p "Enter MySQL password: " DB_PASS
echo
read -p "Enter user table name (default: users): " USER_TABLE
USER_TABLE=${USER_TABLE:-users}
read -p "Enter wallet column name (default: wallet): " WALLET_COLUMN
WALLET_COLUMN=${WALLET_COLUMN:-wallet}
read -p "Enter user ID column name (default: userid): " USER_ID_COLUMN
USER_ID_COLUMN=${USER_ID_COLUMN:-userid}
read -p "Enter installation directory (default: /var/www/html/bot): " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-/var/www/html/bot}

# 2) Prepare directory
INSTALL_PATH="$INSTALL_DIR/bot-daramet.php"
echo "📁 Creating directory $INSTALL_DIR if not exists..."
mkdir -p "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"

# 3) Download the PHP template
TEMPLATE_URL="https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/bot-daramet.php"
echo "⬇️ Downloading bot-daramet.php from GitHub..."
if ! curl -fSL "$TEMPLATE_URL" -o "$INSTALL_PATH"; then
  echo "❌ Failed to download bot-daramet.php"
  exit 1
fi
chmod 644 "$INSTALL_PATH"
echo "✅ bot-daramet.php downloaded to $INSTALL_PATH"

# 4) Detect server IP
echo "🌐 Detecting server public IP..."
ALLOWED_IP=$(curl -s https://api.ipify.org)
echo "Detected IP: $ALLOWED_IP"

# 5) Replace placeholders in PHP
echo "🔄 Replacing placeholders in bot-daramet.php..."
declare -A placeholders=(
  ["{{ALLOWED_IP}}"]="$ALLOWED_IP"
  ["{{TOKEN}}"]="$TOKEN"
  ["{{BOT_TOKEN}}"]="$BOT_TOKEN"
  ["{{ADMIN_CHAT_ID}}"]="$ADMIN_CHAT_ID"
  ["{{DB_HOST}}"]="$DB_HOST"
  ["{{DB_NAME}}"]="$DB_NAME"
  ["{{DB_USER}}"]="$DB_USER"
  ["{{DB_PASS}}"]="$DB_PASS"
  ["__USER_TABLE__"]="$USER_TABLE"
  ["__WALLET_COLUMN__"]="$WALLET_COLUMN"
  ["__USER_ID_COLUMN__"]="$USER_ID_COLUMN"
)
for key in "${!placeholders[@]}"; do
  sed -i "s|$key|${placeholders[$key]}|g" "$INSTALL_PATH"
done

echo "✅ Placeholders replaced successfully."

# 6) Ensure donation_logs table exists
echo "🗄 Ensuring donation_logs table exists..."
if ! mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL
then
  echo "❌ Failed to create or verify donation_logs table."
  exit 1
fi
echo "✅ Table donation_logs is ready."

# 7) Setup cron job every 5 minutes
echo "⏰ Setting up cron job (runs every 5 minutes)..."
CRON_CMD="php $INSTALL_PATH >/dev/null 2>&1"
(crontab -l 2>/dev/null | grep -v -F "$CRON_CMD"; echo "*/5 * * * * $CRON_CMD") | crontab -
echo "✅ Cron job added."

echo "🎉 Installation complete! Script installed at $INSTALL_PATH"
