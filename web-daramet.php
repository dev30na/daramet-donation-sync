<?php
/**
 * web-daramet.php
 * Daramet donation sync script
 * Installer-enabled, Coded by dev30na
 */

// === Configuration Section ===
// IP restriction for security
$allowedIp = '{{ALLOWED_IP}}'; // replaced by installer
if ($_SERVER['REMOTE_ADDR'] !== $allowedIp) {
    http_response_code(403);
    exit('Access denied. (git: dev30na)');
}

// === API credentials ===
$apiToken = '{{TOKEN}}';     // replaced by installer
$apiUrl   = 'https://daramet.com/api/Donates/Messages';

// === Database connection settings ===
$dbHost = '{{DB_HOST}}';
$dbName = '{{DB_NAME}}';
$dbUser = '{{DB_USER}}';
$dbPass = '{{DB_PASS}}';

// === Customizable Wallet Update Settings ===
$userTable    = '__USER_TABLE__';    // replaced by installer
$walletColumn = '__WALLET_COLUMN__'; // replaced by installer
$userIdColumn = '__USER_ID_COLUMN__'; // replaced by installer

// Connect to database
$db = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
if ($db->connect_error) {
    die("DB Connection Failed: " . $db->connect_error);
}

// === Fetch donations from API ===
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

data = json_decode($response, true);
if (!is_array($data)) {
    die("Invalid API response");
}

// === Process each donation ===
foreach ($data as $donation) {
    $donate_id   = $donation['donator_data']['id'];
    $message     = trim($donation['donator_data']['message']);
    $amountRial  = intval($donation['donator_data']['amount']);
    $timestamp   = $donation['donator_data']['timestamp'];

    // Only numeric messages as user IDs
    if (!ctype_digit($message)) {
        continue;
    }
    $userid = $message;

    // Skip already-processed donations
    $check = $db->prepare("SELECT 1 FROM donation_logs WHERE donate_id = ?");
    $check->bind_param("s", $donate_id);
    $check->execute();
    $check->store_result();
    if ($check->num_rows > 0) {
        continue;
    }

    // Convert Rial to Toman
    $amountToman = intval($amountRial / 10);

    // Update user's wallet
    $update = $db->prepare(
        "UPDATE {$userTable} SET {$walletColumn} = {$walletColumn} + ? WHERE {$userIdColumn} = ?"
    );
    $update->bind_param("ii", $amountToman, $userid);
    $update->execute();
    if ($update->affected_rows <= 0) {
        // User not found
        continue;
    }

    // Log donation into database
    $created_at = date("Y-m-d H:i:s", $timestamp);
    $insert = $db->prepare(
        "INSERT INTO donation_logs (donate_id, userid, amount, created_at)
         VALUES (?, ?, ?, ?)"
    );
    $insert->bind_param("siis", $donate_id, $userid, $amountToman, $created_at);
    $insert->execute();
}
