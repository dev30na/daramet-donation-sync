#!/bin/bash

# Developer: dev30na
# Bash Installer for Daramet Donation Sync

echo -e "\n\033[1;34m--- Daramet Donation Sync Installer by dev30na ---\033[0m\n"


read -p "Enter your Daramet API token: " apiToken


read -p "Enter MySQL host (default: localhost): " dbHost
dbHost=${dbHost:-localhost}

read -p "Enter MySQL database name: " dbName
read -p "Enter MySQL username: " dbUser
read -sp "Enter MySQL password: " dbPass
echo


read -p "Enter installation path (default: /var/www/html/pay): " installPath
installPath=${installPath:-/var/www/html/pay}


allowedIp=$(hostname -I | awk '{print $1}')


mkdir -p "$installPath"
chmod -R 755 "$installPath"


echo -e "\nDownloading PHP script..."
curl -sLo "$installPath/web-daramet.php" "https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/web-daramet.php"


sed -i "s|{{TOKEN}}|$apiToken|g" "$installPath/web-daramet.php"
sed -i "s|{{DB_HOST}}|$dbHost|g" "$installPath/web-daramet.php"
sed -i "s|{{DB_NAME}}|$dbName|g" "$installPath/web-daramet.php"
sed -i "s|{{DB_USER}}|$dbUser|g" "$installPath/web-daramet.php"
sed -i "s|{{DB_PASS}}|$dbPass|g" "$installPath/web-daramet.php"
sed -i "s|{{INSTALL_PATH}}|$installPath|g" "$installPath/web-daramet.php"
sed -i "s|{{ALLOWED_IP}}|$allowedIp|g" "$installPath/web-daramet.php"


(crontab -l 2>/dev/null; echo "*/5 * * * * php $installPath/web-daramet.php") | crontab -

echo -e "\n\033[1;32m✅ Installation completed successfully!\033[0m"
echo -e "Installed at: \033[1;33m$installPath/web-daramet.php\033[0m"
echo -e "Allowed IP: \033[1;36m$allowedIp\033[0m"
