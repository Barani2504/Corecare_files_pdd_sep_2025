<?php
// heartbeat.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require 'config.php';

// Check database connection
if (!$conn) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Connection failed: " . mysqli_connect_error()]);
    exit;
}

// Handle OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// =====================
// GET: Fetch heartbeat(s)
// =====================
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $userId = $_GET['user_id'] ?? 1;
    $type = $_GET['type'] ?? 'latest'; // "latest" or "history"

    try {
        if ($type === 'history') {
            // Fetch all readings
            $stmt = $conn->prepare("SELECT bpm, category, created_at 
                                    FROM hr 
                                    WHERE user_id = ? 
                                    ORDER BY created_at DESC");
            if (!$stmt) {
                echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
                exit;
            }
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $rows = $result->fetch_all(MYSQLI_ASSOC);

            echo json_encode(["status" => "success", "records" => $rows]);
        } else {
            // Fetch only the latest
            $stmt = $conn->prepare("SELECT bpm, category, created_at 
                                    FROM hr 
                                    WHERE user_id = ? 
                                    ORDER BY created_at DESC 
                                    LIMIT 1");
            if (!$stmt) {
                echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
                exit;
            }
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $latest = $result->fetch_assoc();

            if ($latest) {
                echo json_encode([
                    "status" => "success",
                    "bpm" => (int)$latest['bpm'],
                    "category" => $latest['category'],
                    "timestamp" => $latest['created_at']
                ]);
            } else {
                echo json_encode([
                    "status" => "success",
                    "bpm" => 0,
                    "category" => "No category",
                    "message" => "No measurements found"
                ]);
            }
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
    }
    exit;
}

// =====================
// POST: Store new heartbeat
// =====================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $userId = $data['user_id'] ?? 1;
    $bpm = $data['bpm'] ?? null;

    // Helper function for category
    function getBpmCategory($bpm) {
        if ($bpm < 60) return "Bradycardia";
        elseif ($bpm <= 100) return "Normal";
        elseif ($bpm <= 120) return "Elevated";
        else return "Tachycardia";
    }

    // Validation
    if ($bpm === null) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "BPM value required"]);
        exit;
    }
    if ($bpm < 30 || $bpm > 220) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "BPM value out of valid range (30–220)"]);
        exit;
    }

    $category = getBpmCategory($bpm);

    try {
        $stmt = $conn->prepare("INSERT INTO hr (user_id, bpm, category) VALUES (?, ?, ?)");
        if (!$stmt) {
            echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
            exit;
        }
        $stmt->bind_param("iis", $userId, $bpm, $category);

        if ($stmt->execute()) {
            echo json_encode([
                "status" => "success",
                "bpm" => (int)$bpm,
                "category" => $category,
                "timestamp" => date('Y-m-d H:i:s')
            ]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Execute failed: " . $stmt->error]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
    }
    exit;
}

// =====================
// If method not allowed
// =====================
http_response_code(405);
echo json_encode(["status" => "error", "message" => "Method not allowed"]);
