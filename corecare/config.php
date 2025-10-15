<?php
// config.php
$servername = "127.0.0.1"; // Use 127.0.0.1 instead of localhost to force TCP connection
$username = "root";         // Default XAMPP username
$password = "";             // Default XAMPP password is empty
$dbname = "corecare";       // Make sure this database exists
$port = 3306;               // Specify port explicitly

// Create connection with port specification
$conn = new mysqli($servername, $username, $password, $dbname, $port);

// Check connection
if ($conn->connect_error) {
    error_log("Database connection failed: " . $conn->connect_error);
    die(json_encode([
        "status" => "error", 
        "message" => "Database connection failed: " . $conn->connect_error
    ]));
}

// Set charset to handle UTF-8 characters properly
$conn->set_charset("utf8mb4");

// Log successful connection for debugging
error_log("Database connection successful");
?>
