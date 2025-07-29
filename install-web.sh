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

# 2. Installation directory
read -p "Enter installation directory (e.g., /var/www/html/pay): " installDir
installDir=${installDir%/}
installPath="$installDir/web-daramet.php"

echo "📁 Using install directory: $installDir"

# 3. Prepare install directory
if [ ! -d "$installDir" ]; then
    echo "📁 Creating directory $installDir..."
    mkdir -p "$installDir"
fi
chmod 755 "$installDir"

# 4. Download PHP script
echo "⬇️ Downloading PHP script to $installPath..."
if ! curl -fSL "https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/web-daramet.php" -o "$installPath"; then
    echo "❌ Download failed! Check URL or internet connection."
    exit 1
fi

# 5. Set permissions
chmod 644 "$installPath"
echo "✅ Download successful: $installPath"

# 6. Fetch server IP
enabledIp=$(curl -s https://api.ipify.org)
echo "🌐 Detected server IP: $enabledIp"

# 7. Replace placeholders in PHP
placeholders=("{{TOKEN}}" "{{DB_HOST}}" "{{DB_NAME}}" "{{DB_USER}}" "{{DB_PASS}}" "__USER_TABLE__" "__WALLET_COLUMN__" "__USER_ID_COLUMN__" "{{ALLOWED_IP}}")
replacements=("$token" "$dbHost" "$dbName" "$dbUser" "$dbPass" "$userTable" "$walletColumn" "$userIdColumn" "$enabledIp")
for i in "${!placeholders[@]}"; do
    sed -i "s|${placeholders[i]}|${replacements[i]}|g" "$installPath"
done
echo "🔄 Placeholders replaced."

# 8. Ensure donation_logs table exists
echo "🗄 Ensuring donation_logs table exists..."
if ! mysql -h "$dbHost" -u "$dbUser" -p"$dbPass" "$dbName" <<SQL
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL
then
    echo "❌ Failed to create or verify 'donation_logs' table."
    exit 1
else
    echo "📦 Table 'donation_logs' ready."
fi

# 9. Setup cron job Setup cron job
cron_line="*/5 * * * * php $installPath >/dev/null 2>&1"
(crontab -l 2>/dev/null | grep -v "$installPath"; echo "$cron_line") | crontab -
echo "⏰ Cron job added: runs every 5 minutes."

echo "🎉 Installation complete! Developed by dev30na <3"
