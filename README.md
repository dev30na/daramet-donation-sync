<p align="left">
  <a href="README.en.md">English Version</a>
</p>

# 💸 دریافت خودکار تراکنش حمایت مالی با PHP + ربات تلگرام

این اسکریپت PHP به شما کمک می‌کند تا به‌صورت خودکار مبلغ حمایت مالی را از API دارمت دریافت کرده، در دیتابیس ذخیره کرده و پیغام را به ربات تلگرام ارسال نماید. همچنین تراکنش تکراری را فیلتر کرده و کیف‌پول کاربران را بروزرسانی می‌کند.

---

## 🎯 ویژگی‌ها

- اتصال مستقیم به API دارامت
- ذخیره پیام‌ها در دیتابیس
- جلوگیری از ثبت پیام‌های تکراری
- ارسال گزارش به ربات تلگرام
- قابل اجرا با کرون‌جاب
- تبدیل ریال به تومان
- اضافه کردن مبلغ به حساب کاربر از طریق ایدی عددی
- چک کرون جاب فقط از ایپی سرور مجاز است
- ربات چت ایدی استخراج میکند
- سایت ایمیل استخراج میکند
---

## ⚙️ مراحل راه‌اندازی

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/install-web.sh)
```
> نصب اسان پیشرفته برای نسخه وبسایت

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dev30na/daramet-donation-sync/main/install-bot.sh)
```
> نصب اسان پیشرفته برای نسخه ربات تلگرام

---

## 🧱 ساختار دیتابیس ثبت لاگ

```sql
CREATE TABLE IF NOT EXISTS donation_logs (
    donate_id VARCHAR(255) PRIMARY KEY,
    userid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
> با این کد میتوانید دستی جدول را بسازید !

## 📬 گزارش‌دهی به تلگرام (نسخه ربات فقط)

اگر توکن و chat_id ربات تلگرام را تنظیم کرده باشید، هر حمایت مالی جدید به‌صورت خودکار برای ادمین و کاربر ارسال خواهد شد

این ویژگی به شما کمک می‌کند بدون نیاز به ورود به پنل یا دیتابیس، فوراً از حمایت‌ها مطلع شوید.

---

## 👤 توسعه‌دهنده

> **سینا dev30na**  
[🌐 GitHub Profile](https://github.com/dev30na)  
 توسعه‌ داده شده با ❤️


## Stargazers over time
[![Stargazers over time](https://starchart.cc/dev30na/daramet-donation-sync.svg?variant=adaptive)](https://starchart.cc/dev30na/daramet-donation-sync)
