<?php
/**
 * web-daramet.php
 * Daramet donation sync script (web version)
 * Installer-enabled, coded by dev30na
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
$dbHost = '{{DB_HOST}}';     // replaced by installer
$dbUser = '{{DB_USER}}';     // replaced by installer
$dbPass = '{{DB_PASS}}';     // replaced by installer
$dbName = '{{DB_NAME}}';     // replaced by installer

// === Wallet Update Settings ===
// Column names replaced by installer; e.g. userTable='users', userIdColumn='email', walletColumn='wallet'
$userTable    = '__USER_TABLE__';
$walletColumn = '__WALLET_COLUMN__';
$userIdColumn = '__USER_ID_COLUMN__';

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

$data = json_decode($response, true);
if (!is_array($data)) {
    die("Invalid API response");
}

// === Process each donation ===
foreach ($data as $donation) {
    $donate_id  = $donation['donator_data']['id'];
    $email      = trim($donation['donator_data']['message']);
    $amountRial = intval($donation['donator_data']['amount']);
    $timestamp  = $donation['donator_data']['timestamp'];

    // Only accept valid email addresses
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        continue;
    }

    // Skip duplicates
    $check = $db->prepare("SELECT 1 FROM donation_logs WHERE donate_id = ?");
    $check->bind_param("s", $donate_id);
    $check->execute();
    $check->store_result();
    if ($check->num_rows > 0) {
        continue;
    }

    // Convert Rial to Toman
    $amountToman = intval($amountRial / 10);

    // Update user's wallet by ((email))
    $update = $db->prepare(
        "UPDATE {$userTable}
         SET {$walletColumn} = {$walletColumn} + ?
         WHERE {$userIdColumn} = ?"
    );
    $update->bind_param("is", $amountToman, $email);
    $update->execute();
    if ($update->affected_rows <= 0) {
        // No matching user with that email
        continue;
    }

    // Log donation in database
    $created_at = date("Y-m-d H:i:s", $timestamp);
    $insert = $db->prepare(
        "INSERT INTO donation_logs (donate_id, userid, amount, created_at)
         VALUES (?, ?, ?, ?)"
    );
    $insert->bind_param("ssis", $donate_id, $email, $amountToman, $created_at);
    $insert->execute();
}
