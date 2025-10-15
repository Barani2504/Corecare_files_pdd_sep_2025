<?php
// login.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

$input = json_decode(file_get_contents("php://input"), true);

if (!isset($input['emailOrPhone']) || !isset($input['password'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Email/phone and password required"]);
    exit;
}

$emailOrPhone = trim($input['emailOrPhone']);
$password = trim($input['password']);

// Determine if input is email or phone
$isEmail = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL);
$email = $isEmail ? $emailOrPhone : null;
$phone = !$isEmail ? $emailOrPhone : null;

// Fetch user by email or phone
$sql = "SELECT id, password FROM users WHERE email = ? OR phone = ?";
$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["status"=>"error","message"=>"SQL Prepare Failed: ".$conn->error]);
    exit;
}

$stmt->bind_param("ss", $email, $phone);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    // Plain text password check
    if ($password === $row['password']) {
        echo json_encode([
            "status" => "success",
            "message" => "Login successful",
            "data" => ["user_id" => $row['id'], "emailOrPhone" => $emailOrPhone]
        ]);
    } else {
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Invalid password"]);
    }
} else {
    http_response_code(404);
    echo json_encode(["status" => "error", "message" => "User not found"]);
}

$stmt->close();
$conn->close();
?>
