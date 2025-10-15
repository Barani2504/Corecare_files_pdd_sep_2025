<?php
// weight.php - Enhanced version with better error handling and Swift compatibility
ob_start();
ini_set('display_errors', 0);
ini_set('log_errors', 1);

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

function sendResponse($data) {
    ob_clean();
    echo json_encode($data);
    exit;
}

function sendError($message, $code = 400) {
    http_response_code($code);
    sendResponse(["status" => "error", "message" => $message]);
}

require_once 'config.php';
if (!isset($conn) || !$conn) {
    sendError("Database connection failed", 500);
}

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // === GET: Fetch latest BMI by user_id ===
        $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
        if ($userId <= 0) {
            sendError("Valid user_id is required for GET");
        }

        $stmt = $conn->prepare("SELECT weight, height, bmi, bmi_category, recorded_at 
                                FROM bmi WHERE user_id = ? 
                                ORDER BY recorded_at DESC LIMIT 1");
        if (!$stmt) {
            sendError("Prepare failed: " . $conn->error, 500);
        }

        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($row = $result->fetch_assoc()) {
            // Enhanced response format for Swift compatibility
            $responseData = [
                "user_id" => (int)$userId,
                "weight" => (float)$row['weight'],
                "height" => (float)$row['height'],
                "bmi" => (float)$row['bmi'],
                "category" => $row['bmi_category'] ?? "Unknown", // Primary field
                "bmi_category" => $row['bmi_category'] ?? "Unknown", // Fallback field
                "recorded_at" => $row['recorded_at']
            ];
            
            sendResponse([
                "status" => "success", 
                "data" => $responseData,
                "message" => "Weight data retrieved successfully"
            ]);
        } else {
            sendError("No BMI record found for this user", 404);
        }

    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // === POST: Insert new weight/bmi ===

        // Try JSON input first
        $input = json_decode(file_get_contents("php://input"), true);

        if (is_array($input) && !empty($input)) {
            $userId = isset($input['user_id']) ? $input['user_id'] : null;
            $weight = isset($input['weight']) ? $input['weight'] : null;
            $height = isset($input['height']) ? $input['height'] : null;
        } else {
            // Fallback to form-data
            $userId = isset($_POST['user_id']) ? $_POST['user_id'] : null;
            $weight = isset($_POST['weight']) ? $_POST['weight'] : null;
            $height = isset($_POST['height']) ? $_POST['height'] : null;
        }

        // Enhanced validation
        if (!$userId || !is_numeric($userId) || $userId <= 0) {
            sendError("Valid user_id is required");
        }
        if (!$weight || !is_numeric($weight) || $weight <= 0 || $weight > 1000) {
            sendError("Valid weight is required (0-1000 kg)");
        }
        if (!$height || !is_numeric($height) || $height <= 0 || $height > 300) {
            sendError("Valid height is required (0-300 cm)");
        }

        $userId = (int)$userId;
        $weight = (float)$weight;
        $height = (float)$height;

        // BMI calculation with validation
        $height_m = $height / 100;
        if ($height_m <= 0) {
            sendError("Invalid height for BMI calculation");
        }
        
        $bmi = round($weight / ($height_m * $height_m), 1);

        // BMI categorization
        if ($bmi < 18.5) {
            $category = "Underweight";
        } elseif ($bmi < 25.0) {
            $category = "Normal";
        } elseif ($bmi < 30.0) {
            $category = "Overweight";
        } else {
            $category = "Obese";
        }

        // Insert into bmi table
        $stmt = $conn->prepare("INSERT INTO bmi (user_id, weight, height, bmi, bmi_category) VALUES (?, ?, ?, ?, ?)");
        if (!$stmt) {
            sendError("Prepare failed: " . $conn->error, 500);
        }
        
        $stmt->bind_param("iddds", $userId, $weight, $height, $bmi, $category);
        if (!$stmt->execute()) {
            sendError("Insert failed: " . $stmt->error, 500);
        }
        $stmt->close();

        // Return enhanced response format
        sendResponse([
            "status" => "success",
            "message" => "BMI record saved successfully",
            "data" => [
                "user_id" => $userId,
                "weight" => $weight,
                "height" => $height,
                "bmi" => $bmi,
                "category" => $category,        // Primary field
                "bmi_category" => $category,    // Fallback field
                "recorded_at" => date('Y-m-d H:i:s')
            ]
        ]);
    } else {
        sendError("Method not allowed", 405);
    }
} catch (Exception $e) {
    error_log("Weight.php error: " . $e->getMessage());
    sendError("Server error: Please try again later", 500);
} finally {
    if (isset($conn) && $conn) {
        $conn->close();
    }
}
?>