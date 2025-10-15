<?php
header("Content-Type: application/json");
ini_set('display_errors', 0);
error_reporting(0);

require 'config.php';

// Prevent stray whitespace
ob_start();

$input = json_decode(file_get_contents("php://input"), true);
$response = ['success' => false, 'message' => 'Unknown error'];

if (isset($input['emailOrPhone'], $input['new_password'], $input['confirm_password'])) {
    $emailOrPhone   = trim($input['emailOrPhone']);
    $newPassword    = trim($input['new_password']);
    $confirmPassword = trim($input['confirm_password']);

    // Check if user exists
    $stmt = $conn->prepare("SELECT id FROM users WHERE email = ? OR phone = ?");
    if ($stmt) {
        $stmt->bind_param("ss", $emailOrPhone, $emailOrPhone);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            $response = ['success' => false, 'message' => 'User not found'];
        } else {
            // CASE 1: Verify-only request
            if ($newPassword === "" && $confirmPassword === "") {
                $response = ['success' => true, 'message' => 'User exists. You can reset password.'];
            } else {
                // CASE 2: Reset password
                if ($newPassword !== $confirmPassword) {
                    $response = ['success' => false, 'message' => 'Passwords do not match'];
                } elseif (strlen($newPassword) < 8) {
                    $response = ['success' => false, 'message' => 'Password too short'];
                } else {
                    $user = $result->fetch_assoc();
                    $userId = $user['id'];

                    $update = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
                    if ($update) {
                        $update->bind_param("si", $newPassword, $userId);
                        if ($update->execute()) {
                            $response = ['success' => true, 'message' => 'Password reset successfully'];
                        } else {
                            $response = ['success' => false, 'message' => 'Failed to update password'];
                        }
                    } else {
                        $response = ['success' => false, 'message' => 'Database error'];
                    }
                }
            }
        }
    } else {
        $response = ['success' => false, 'message' => 'Database error'];
    }
}

echo json_encode($response);
ob_end_flush();
$conn->close();
?>
