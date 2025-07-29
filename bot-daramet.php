<?php
// Access IP (sec xDDD)
$allowedIp = '{{ALLOWED_IP}}'; //your IP Host our Server
if ($_SERVER['REMOTE_ADDR'] !== $allowedIp) {
    http_response_code(403);
    exit('Access denied. (git: dev30na)');
}

// Main Config
$apiToken    = "{{TOKEN}}"; // api ID https://daramet.com
$apiUrl      = "https://daramet.com/api/Donates/Messages"; // dont touch
$botToken    = "{{BOT_TOKEN}}"; // Token telegram bot
$adminChatId = "{{ADMIN_CHAT_ID}}";  // Admin Log (GP ID & Admin ID & Channel ID)

// CONFIG DATABASE
$db = new mysqli("{{DB_HOST}}", "{{DB_USER}}", "{{DB_PASS}}", "{{DB_NAME}}");
if ($db->connect_error) {
    die("DB Connection Failed: " . $db->connect_error);
}

// Telegram Notif
function sendTelegram($chatId, $message) {
    global $botToken;
    $url = "https://api.telegram.org/bot{$botToken}/sendMessage";
    $post = [
        'chat_id' => $chatId,
        'text'    => $message,
        'parse_mode' => 'HTML'
    ];
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,      $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS,   $post);
    curl_exec($ch);
    curl_close($ch);
}

// Api Call
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: {$apiToken}",
    "Accept: application/json"
]);
$response = curl_exec($ch);
curl_close($ch);

if (!$response) {
    die("API Error: No response");
}

$data = json_decode($response, true);
if (!is_array($data)) {
    die("Invalid API response");
}

// Check data
foreach ($data as $donation) {
    $donate_id = $donation['donator_data']['id'];
    $message   = trim($donation['donator_data']['message']);
    $amountRial= intval($donation['donator_data']['amount']);
    $timestamp = $donation['donator_data']['timestamp'];

    // Only accept numbers
    if (!ctype_digit($message)) {
        continue;
    }
    $userid = $message;

    // Repeated donations
    $check = $db->prepare("SELECT 1 FROM donation_logs WHERE donate_id = ?");
    $check->bind_param("s", $donate_id);
    $check->execute();
    $check->store_result();
    if ($check->num_rows > 0) {
        continue;
    }

    // Change Rial to Toman
    $amountToman = intval($amountRial / 10);

    // Added to wallet
    $update = $db->prepare("UPDATE {{USER_TABLE}} SET {{WALLET_COLUMN}} = {{WALLET_COLUMN}} + ? WHERE {{USER_ID_COLUMN}} = ?");
    $update->bind_param("ii", $amountToman, $userid);
    $update->execute();
    if ($update->affected_rows <= 0) {
        // Not a user
        continue;
    }

    // Added to log in database
    $created_at = date("Y-m-d H:i:s", $timestamp);
    $insert = $db->prepare(
        "INSERT INTO donation_logs (donate_id, userid, amount, created_at)
         VALUES (?, ?, ?, ?)"
    );
    $insert->bind_param("siis", $donate_id, $userid, $amountToman, $created_at);
    $insert->execute();

    // Log Admin
    $adminMsg = "✅ <b>Donation Received</b>\n"
              . "👤 UserID: <code>{$userid}</code>\n"
              . "💰 Amount: {$amountToman} تومان\n"
              . "⏰ Time: {$created_at}\n"
              . "🆔 DonateID: {$donate_id}";
    sendTelegram($adminChatId, $adminMsg);

    // Log User
    $userMsg = "🎉 درود!\n"
             . "💳 مبلغ <b>{$amountToman} تومان</b> به کیف پول شما افزوده شد.\n\n"
             . "🛒 برای نهایی کردن خرید خود، هنگام پرداخت دکمه «پرداخت از کیف پول» را بزنید.";
    sendTelegram($userid, $userMsg);
}
