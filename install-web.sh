#!/bin/bash

# Installer by dev30na
set -e

echo "🔧 Starting Donation Script Installer..."

# Gather inputs
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

# Create folder if not exists
installDir=$(dirname "$installPath")
if [ ! -d "$installDir" ]; then
    echo "📁 Creating directory $installDir..."
    mkdir -p "$installDir"
fi

# Download PHP script
echo "⬇️ Downloading PHP script to $installPath..."
curl -sL "https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/web-daramet.php" -o "$installPath"

# Check if download succeeded
if [ ! -f "$installPath" ]; then
    echo "❌ Download failed! Could not find $installPath"
    exit 1
fi

# Make sure server IP is allowed
allowedIp=$(curl -s https://api.ipify.org)

# Replace variables in PHP file
echo "🔄 Replacing placeholders..."
sed -i "s|{{TOKEN}}|$token|g" "$installPath"
sed -i "s|{{DB_HOST}}|$dbHost|g" "$installPath"
sed -i "s|{{DB_NAME}}|$dbName|g" "$installPath"
sed -i "s|{{DB_USER}}|$dbUser|g" "$installPath"
sed -i "s|{{DB_PASS}}|$dbPass|g" "$installPath"
sed -i "s|__USER_TABLE__|$userTable|g" "$installPath"
sed -i "s|__WALLET_COLUMN__|$walletColumn|g" "$installPath"
sed -i "s|__USER_ID_COLUMN__|$userIdColumn|g" "$installPath"
sed -i "s|{{ALLOWED_IP}}|$allowedIp|g" "$installPath"

# Set permissions
chmod 755 "$installDir"
chmod 644 "$installPath"

# Ensure donation_logs table exists
echo "🗄 Creating donation_logs table (if not exists)..."
mysql -h "$dbHost" -u "$dbUser" -p"$dbPass" "$dbName" <<SQL
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL

# Add cron job
cron_line="*/5 * * * * php $installPath >/dev/null 2>&1"
(crontab -l 2>/dev/null | grep -v "$installPath" ; echo "$cron_line") | crontab -

# Done
echo "✅ Installation complete. Sync runs every 5 minutes."
echo "💡 Script path: $installPath"
echo "💻 Server IP allowed: $allowedIp"
echo "👨‍💻 Developed by dev30na"
