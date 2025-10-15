<?php
//user.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require 'config.php';

// Handle OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Check database connection
if (!$conn) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Connection failed: " . mysqli_connect_error()]);
    exit;
}

// GET USER DETAILS
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
    if (!$userId || $userId <= 0) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid user_id provided"]);
        exit;
    }

    try {
        $stmt = $conn->prepare("
            SELECT 
                id as user_id,
                IFNULL(name,'') AS name,
                IFNULL(age,0) AS age,
                IFNULL(sex,'') AS sex,
                IFNULL(height,'0') AS height,
                IFNULL(phone,'') AS phone,
                IFNULL(email,'') AS email,
                IFNULL(profile_picture,'') AS profile_picture
            FROM users WHERE id=?
        ");
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database prepare error: " . $conn->error]);
            exit;
        }
        $stmt->bind_param("i", $userId);
        if (!$stmt->execute()) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database execute error: " . $stmt->error]);
            exit;
        }
        $result = $stmt->get_result();
        if ($row = $result->fetch_assoc()) {
            echo json_encode(["status" => "success", "data" => $row]);
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
        }
        $stmt->close();
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
    }
    exit;
}

// POST: UPDATE USER DETAILS  
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rawInput = file_get_contents('php://input');
    if (empty($rawInput)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "No data received"]);
        exit;
    }
    
    // Log the received data for debugging
    error_log("Received JSON: " . $rawInput);
    
    $data = json_decode($rawInput, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid JSON data: " . json_last_error_msg()]);
        exit;
    }

    // Extract data
    $userId = isset($data['user_id']) ? intval($data['user_id']) : null;
    $name   = isset($data['name']) ? trim($data['name']) : '';
    $age    = isset($data['age']) ? intval($data['age']) : 0;
    $sex    = isset($data['sex']) ? trim($data['sex']) : '';
    $height = isset($data['height']) ? trim($data['height']) : '0';
    $phone  = isset($data['phone']) ? trim($data['phone']) : '';
    $email  = isset($data['email']) ? trim($data['email']) : '';
    $profilePicture = isset($data['profile_picture']) ? trim($data['profile_picture']) : '';

    // Log extracted data for debugging
    error_log("Extracted data - UserID: $userId, Name: $name, Age: $age, Sex: $sex, Height: $height, Phone: $phone, Email: $email, Avatar: $profilePicture");

    // Validate required fields
    if (!$userId || $userId <= 0) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid user_id"]);
        exit;
    }
    if (empty($name)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Name is required"]);
        exit;
    }
    if ($age <= 0) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Valid age is required"]);
        exit;
    }
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Valid email is required"]);
        exit;
    }

    try {
        // Check if user exists
        $checkStmt = $conn->prepare("SELECT id FROM users WHERE id = ?");
        if (!$checkStmt) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database prepare error: " . $conn->error]);
            exit;
        }
        $checkStmt->bind_param("i", $userId);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        if ($checkResult->num_rows === 0) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
            $checkStmt->close();
            exit;
        }
        $checkStmt->close();

        // FIXED: Update user with CORRECT bind param count and types
        $stmt = $conn->prepare("UPDATE users SET name=?, age=?, sex=?, height=?, phone=?, email=?, profile_picture=? WHERE id=?");
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database prepare error: " . $conn->error]);
            exit;
        }
        
        // FIXED: 8 parameters - "sisssssi" (8 chars for 8 values)
        $stmt->bind_param("sisssssi", $name, $age, $sex, $height, $phone, $email, $profilePicture, $userId);
        
        if (!$stmt->execute()) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Update failed: " . $stmt->error]);
            $stmt->close();
            exit;
        }
        
        $affectedRows = $stmt->affected_rows;
        $stmt->close();

        if ($affectedRows > 0) {
            echo json_encode([
                "status" => "success", 
                "message" => "Profile updated successfully"
            ]);
        } else {
            echo json_encode([
                "status" => "success", 
                "message" => "No changes made to profile"
            ]);
        }

    } catch (Exception $e) {
        error_log("Database error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
    }
    exit;
}

// DELETE: DELETE USER ACCOUNT
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $rawInput = file_get_contents('php://input');
    if (empty($rawInput)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "No data received"]);
        exit;
    }
    
    // Log the received data for debugging
    error_log("Delete request JSON: " . $rawInput);
    
    $data = json_decode($rawInput, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid JSON data: " . json_last_error_msg()]);
        exit;
    }

    // Extract user ID
    $userId = isset($data['user_id']) ? intval($data['user_id']) : null;
    
    // Validate user ID
    if (!$userId || $userId <= 0) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid user_id provided"]);
        exit;
    }

    try {
        // Check if user exists before deletion
        $checkStmt = $conn->prepare("SELECT id, name, email FROM users WHERE id = ?");
        if (!$checkStmt) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database prepare error: " . $conn->error]);
            exit;
        }
        $checkStmt->bind_param("i", $userId);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        
        if ($checkResult->num_rows === 0) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
            $checkStmt->close();
            exit;
        }
        
        $userData = $checkResult->fetch_assoc();
        $checkStmt->close();
        
        // Log user details for audit trail
        error_log("Deleting user account - ID: $userId, Name: " . $userData['name'] . ", Email: " . $userData['email']);

        // Begin transaction for data integrity
        $conn->autocommit(false);
        
        try {
            // Delete related data first (if you have other tables with foreign keys)
            // Example: Delete user's health records, notifications, etc.
            // You can uncomment and modify these based on your database schema
            
            /*
            // Delete user's health records
            $deleteHealthStmt = $conn->prepare("DELETE FROM health_records WHERE user_id = ?");
            if ($deleteHealthStmt) {
                $deleteHealthStmt->bind_param("i", $userId);
                $deleteHealthStmt->execute();
                $deleteHealthStmt->close();
                error_log("Deleted health records for user ID: $userId");
            }
            
            // Delete user's notifications
            $deleteNotifStmt = $conn->prepare("DELETE FROM notifications WHERE user_id = ?");
            if ($deleteNotifStmt) {
                $deleteNotifStmt->bind_param("i", $userId);
                $deleteNotifStmt->execute();
                $deleteNotifStmt->close();
                error_log("Deleted notifications for user ID: $userId");
            }
            
            // Delete user's sessions
            $deleteSessionStmt = $conn->prepare("DELETE FROM user_sessions WHERE user_id = ?");
            if ($deleteSessionStmt) {
                $deleteSessionStmt->bind_param("i", $userId);
                $deleteSessionStmt->execute();
                $deleteSessionStmt->close();
                error_log("Deleted sessions for user ID: $userId");
            }
            */
            
            // Finally delete the user account
            $deleteUserStmt = $conn->prepare("DELETE FROM users WHERE id = ?");
            if (!$deleteUserStmt) {
                throw new Exception("Database prepare error: " . $conn->error);
            }
            
            $deleteUserStmt->bind_param("i", $userId);
            if (!$deleteUserStmt->execute()) {
                throw new Exception("User deletion failed: " . $deleteUserStmt->error);
            }
            
            $affectedRows = $deleteUserStmt->affected_rows;
            $deleteUserStmt->close();
            
            if ($affectedRows > 0) {
                // Commit the transaction
                $conn->commit();
                
                error_log("Successfully deleted user account - ID: $userId");
                
                echo json_encode([
                    "status" => "success", 
                    "message" => "Account deleted successfully"
                ]);
            } else {
                throw new Exception("No user was deleted - possibly already deleted");
            }
            
        } catch (Exception $e) {
            // Rollback the transaction on error
            $conn->rollback();
            throw $e;
        }
        
        // Restore autocommit
        $conn->autocommit(true);

    } catch (Exception $e) {
        error_log("Account deletion error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Account deletion failed: " . $e->getMessage()]);
    }
    exit;
}

// METHOD NOT ALLOWED
http_response_code(405);
echo json_encode(["status" => "error", "message" => "Method not allowed"]);
?>
