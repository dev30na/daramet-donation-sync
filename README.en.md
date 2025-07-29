<p align="left">
  <a href="README.md">نسخه فارسی</a>

# 💸 Automated Donation Transactions with PHP + Telegram Bot

This PHP script helps you automatically fetch donation transactions from the Daramet API, store them in your database, and send notifications via a Telegram bot. It filters out duplicate transactions, updates user wallets, and converts amounts from Rial to Toman.

---

## 🎯 Features

* Direct connection to Daramet API
* Store donation data in MySQL
* Prevent duplicate entries
* Send notifications to Telegram (admin and user)
* Run via cron job every 5 minutes
* Amount conversion from Rial to Toman
* Increment user wallet balance by user ID
* IP-based access control (only server IP allowed)
* Chatbot extracts ID
* Site extracts email
---

## ⚙️ Quick Setup

Run the appropriate installer script with one of the following commands:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/install-web.sh)
```

> Advanced one-line installer for the **web** version

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/install-bot.sh)
```

> Advanced one-line installer for the **Telegram bot** version

---

## 🧱 Database Table: `donation_logs`

Use this SQL to manually create the donation log table if needed:

```sql
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 📬 Telegram Notifications (Bot Version Only)

If you provide your Telegram bot token and chat IDs, every new donation will be sent automatically to the admin and the donor. This helps you stay updated without logging into a control panel.

---

## 👤 Developer

> **Sina (dev30na)**
> [🌐 GitHub Profile](https://github.com/dev30na)
> Developed with ❤️

