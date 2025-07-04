<p align="left">
  <a href="README.md">نسخه فارسی</a>
</p>

# 💸 Auto-fetch Donation Transactions with PHP + Telegram Bot

This PHP script helps you automatically retrieve donation transactions from the Daramet API, store them in a database, and send the messages to a Telegram bot.  
It also filters duplicate transactions and updates user wallet balances.

---

## 🎯 Features

- Direct connection to the Daramet API
- Store donation messages in the database
- Prevent duplicate transactions
- Send reports to a Telegram bot
- Cronjob-compatible
- Convert Rial to Toman automatically
- Add donation amount to user's wallet via numeric user ID
- Cronjob access is restricted to authorized server IP only

---

## ⚙️ Setup Steps

1. Upload the `donate.php` file to your server.
2. Configure database access and Telegram token inside the file.
3. Add a cronjob similar to the following:

```
*/5 * * * * php /home/username/path/to/donate.php > /dev/null 2>&1
```

> This will execute the script every 5 minutes.

---

## 🧱 Database Structure

```sql
-- Users table
CREATE TABLE `users` (
  `id` INT PRIMARY KEY,
  `wallet` INT DEFAULT 0
);

-- Donation messages table
CREATE TABLE `orders_list` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT,
  `amount` INT,
  `created_at` DATETIME,
  `unique_code` VARCHAR(255)
); 
```

---

## 📬 Telegram Reporting

If you've set the Telegram bot token and `chat_id` in the `donate.php` file, each new donation will automatically be sent to both the admin and the user.

This feature helps you receive instant updates on donations without needing to access the panel or database.

---

## 👤 Developer

> **Sina (dev30na)**  
[🌐 GitHub Profile](https://github.com/dev30na)  
Developed with ❤️
