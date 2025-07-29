#!/bin/bash

set -euo pipefail

echo "🔧 Starting Donation Script Installer..."


read -p "Enter your Daramet API token: " token


read -p "Database host (e.g., localhost): " dbHost
read -p "Database name: " dbName
read -p "Database username: " dbUser
read -s -p "Database password: " dbPass
echo


read -p "User table name: " userTable
read -p "Wallet column name: " walletColumn
read -p "User ID column name: " userIdColumn



read -p "Enter full install path (e.g., /var/www/html/web-daramet.php): " installPath


echo "⬇️ Downloading PHP script..."
curl -sL "https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/web-daramet.php" -o "$installPath"


if [ ! -f "$installPath" ]; then
    echo "❌ Download failed! Could not find $installPath"
    exit 1
fi


allowedIp=$(curl -s https://api.ipify.org)


sed -i "s|{{TOKEN}}|$token|g" "$installPath"
sed -i "s|{{DB_HOST}}|$dbHost|g" "$installPath"
sed -i "s|{{DB_NAME}}|$dbName|g" "$installPath"
sed -i "s|{{DB_USER}}|$dbUser|g" "$installPath"
sed -i "s|{{DB_PASS}}|$dbPass|g" "$installPath"
sed -i "s|__USER_TABLE__|$userTable|g" "$installPath"
sed -i "s|__WALLET_COLUMN__|$walletColumn|g" "$installPath"
sed -i "s|__USER_ID_COLUMN__|$userIdColumn|g" "$installPath"
sed -i "s|{{ALLOWED_IP}}|$allowedIp|g" "$installPath"

echo "✅ Values replaced in $installPath"


mysql -h "$dbHost" -u "$dbUser" -p"$dbPass" "$dbName" <<SQL
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL

echo "📦 Table 'donation_logs' ensured."


(crontab -l 2>/dev/null; echo "*/5 * * * * php $installPath >/dev/null 2>&1") | crontab -
echo "⏰ Cron job added."

echo "🎉 Installation complete. Your donation sync is ready."
echo "Coded BY dev30na <3"
