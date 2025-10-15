<?php
// register.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Include database connection
require_once 'config.php';

// Check if connection exists
if (!isset($conn) || $conn === null) {
    error_log("Database connection failed in register.php");
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed",
        "user_id" => 0
    ]);
    exit;
}

// Check connection error
if ($conn->connect_error) {
    error_log("Database connection error: " . $conn->connect_error);
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection error: " . $conn->connect_error,
        "user_id" => 0
    ]);
    exit;
}

// Get and validate input data
$input = json_decode(file_get_contents("php://input"), true);

// Check for JSON decode errors
if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("JSON decode error: " . json_last_error_msg());
    http_response_code(400);
    echo json_encode([
        "status" => "error", 
        "message" => "Invalid JSON format",
        "user_id" => 0
    ]);
    exit;
}

if (!isset($input['emailOrPhone']) || !isset($input['password'])) {
    error_log("Missing required fields: emailOrPhone or password");
    http_response_code(400);
    echo json_encode([
        "status" => "error", 
        "message" => "Email/phone and password required",
        "user_id" => 0
    ]);
    exit;
}

$emailOrPhone = trim($input['emailOrPhone']);
$password = trim($input['password']);

// Validate input
if (empty($emailOrPhone) || empty($password)) {
    error_log("Empty fields provided");
    http_response_code(400);
    echo json_encode([
        "status" => "error", 
        "message" => "Email/phone and password cannot be empty",
        "user_id" => 0
    ]);
    exit;
}

// Validate password strength (matching Swift validation)
if (!preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$/', $password)) {
    error_log("Password validation failed for: " . $emailOrPhone);
    http_response_code(400);
    echo json_encode([
        "status" => "error", 
        "message" => "Password must be at least 8 characters with uppercase, lowercase, number, and symbol",
        "user_id" => 0
    ]);
    exit;
}

// Determine if input is email or phone
$isEmail = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL);
if (!$isEmail) {
    // Validate phone format (matching Swift validation)
    if (!preg_match('/^\+?[0-9 ]{7,15}$/', $emailOrPhone)) {
        error_log("Invalid email/phone format: " . $emailOrPhone);
        http_response_code(400);
        echo json_encode([
            "status" => "error", 
            "message" => "Please enter a valid email or phone number",
            "user_id" => 0
        ]);
        exit;
    }
}

$email = $isEmail ? $emailOrPhone : null;
$phone = !$isEmail ? $emailOrPhone : null;

// Log the attempt
error_log("Registration attempt for: " . $emailOrPhone);

// Check if user already exists
$checkSql = "SELECT id FROM users WHERE email = ? OR phone = ?";
$stmt = $conn->prepare($checkSql);

if (!$stmt) {
    error_log("Prepare statement failed for user check: " . $conn->error);
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database prepare error: " . $conn->error,
        "user_id" => 0
    ]);
    exit;
}

$stmt->bind_param("ss", $email, $phone);

if (!$stmt->execute()) {
    error_log("Execute failed for user check: " . $stmt->error);
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database execute error: " . $stmt->error,
        "user_id" => 0
    ]);
    exit;
}

$result = $stmt->get_result();

if ($result->num_rows > 0) {
    error_log("User already exists: " . $emailOrPhone);
    http_response_code(409);
    echo json_encode([
        "status" => "error", 
        "message" => "User with this email or phone already exists",
        "user_id" => 0
    ]);
    $stmt->close();
    exit;
}

$stmt->close();

// Insert new user
$insertSql = "INSERT INTO users (email, phone, password, updated_at) VALUES (?, ?, ?, NOW())";
$stmt = $conn->prepare($insertSql);

if (!$stmt) {
    error_log("Prepare statement failed for user insert: " . $conn->error);
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database prepare error: " . $conn->error,
        "user_id" => 0
    ]);
    exit;
}

$stmt->bind_param("sss", $email, $phone, $password);

if ($stmt->execute()) {
    $userId = $conn->insert_id;
    
    // Log successful registration
    error_log("User registered successfully: ID=$userId, Email/Phone=$emailOrPhone");
    
    // Return consistent format matching RegistrationView expectations
    echo json_encode([
        "status" => "success",
        "message" => "User registered successfully",
        "user_id" => (int)$userId
    ]);
    
} else {
    error_log("User insert failed: " . $stmt->error);
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => "Registration failed: " . $stmt->error,
        "user_id" => 0
    ]);
}

$stmt->close();
$conn->close();
?>