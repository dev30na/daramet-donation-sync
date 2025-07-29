#!/bin/bash
# Installer by dev30na
set -euo pipefail

echo "🔧 Starting Donation Script Installer..."

# 1. User inputs
read -p "Enter your Daramet API token: " token
read -p "Database host (e.g., localhost): " dbHost
read -p "Database name: " dbName
read -p "Database username: " dbUser
read -s -p "Database password: " dbPass
echo
read -p "User table name: " userTable
read -p "Wallet column name: " walletColumn
read -p "User ID column name: " userIdColumn
read -p "Enter full install path for PHP script (e.g., /var/www/html/pay/web-daramet.php): " installPath

# 2. Prepare install directory
installDir=$(dirname "$installPath")
if [ ! -d "$installDir" ]; then
    echo "📁 Creating directory $installDir..."
    mkdir -p "$installDir"
fi
chmod 755 "$installDir"

# 3. Download PHP script
echo "⬇️ Downloading PHP script..."
if ! curl -fSL "https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/web-daramet.php" -o "$installPath"; then
    echo "❌ Download failed! Check URL or internet connection."
    exit 1
fi

# 4. Set permissions
chmod 644 "$installPath"
echo "✅ Download successful: $installPath"

# 5. Fetch server IP
enabledIp=$(curl -s https://api.ipify.org)
echo "🌐 Detected server IP: $enabledIp"

# 6. Replace placeholders in PHP
placeholders=("{{TOKEN}}" "{{DB_HOST}}" "{{DB_NAME}}" "{{DB_USER}}" "{{DB_PASS}}" "__USER_TABLE__" "__WALLET_COLUMN__" "__USER_ID_COLUMN__" "{{ALLOWED_IP}}")
replacements=("$token" "$dbHost" "$dbName" "$dbUser" "$dbPass" "$userTable" "$walletColumn" "$userIdColumn" "$enabledIp")
for i in "${!placeholders[@]}"; do
    sed -i "s|${placeholders[i]}|${replacements[i]}|g" "$installPath"
done
echo "🔄 Placeholders replaced."

# 7. Ensure donation_logs table exists
echo "🗄 Ensuring donation_logs table exists..."
mysql -h "$dbHost" -u "$dbUser" -p"$dbPass" "$dbName" <<SQL
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL

echo "📦 Table ready."

# 8. Setup cron job
cron_line="*/5 * * * * php $installPath >/dev/null 2>&1"
(crontab -l 2>/dev/null | grep -v "$installPath"; echo "$cron_line") | crontab -
echo "⏰ Cron job added: runs every 5 minutes."

echo "🎉 Installation complete! Developed by dev30na <3"
