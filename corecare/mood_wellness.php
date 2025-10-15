<?php
// mood_wellness.php
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
// GET: Fetch mood/wellness data
// =====================
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $userId = $_GET['user_id'] ?? 1;
    $type = $_GET['type'] ?? 'latest'; // "latest" or "history"

    try {
        if ($type === 'history') {
            // For history, we'd need a separate mood_entries table
            // This is a placeholder for latest data only
            $stmt = $conn->prepare("SELECT latest_mood, latest_symptoms, latest_heart_rate, 
                                    latest_context_note, mood_updated_at 
                                    FROM users 
                                    WHERE id = ?");
            if (!$stmt) {
                echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
                exit;
            }
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $row = $result->fetch_assoc();

            if ($row) {
                $symptoms = $row['latest_symptoms'] ? explode(',', $row['latest_symptoms']) : [];
                echo json_encode([
                    "status" => "success",
                    "records" => [
                        [
                            "mood" => $row['latest_mood'],
                            "symptoms" => $symptoms,
                            "heart_rate" => (int)$row['latest_heart_rate'],
                            "context_note" => $row['latest_context_note'],
                            "updated_at" => $row['mood_updated_at']
                        ]
                    ]
                ]);
            } else {
                echo json_encode(["status" => "success", "records" => []]);
            }
        } else {
            // Fetch only the latest
            $stmt = $conn->prepare("SELECT latest_mood, latest_symptoms, latest_heart_rate, 
                                    latest_context_note, mood_updated_at 
                                    FROM users 
                                    WHERE id = ?");
            if (!$stmt) {
                echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
                exit;
            }
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $latest = $result->fetch_assoc();

            if ($latest && $latest['latest_mood']) {
                $symptoms = $latest['latest_symptoms'] ? explode(',', $latest['latest_symptoms']) : [];
                echo json_encode([
                    "status" => "success",
                    "mood" => $latest['latest_mood'],
                    "symptoms" => $symptoms,
                    "heart_rate" => (int)$latest['latest_heart_rate'],
                    "context_note" => $latest['latest_context_note'],
                    "timestamp" => $latest['mood_updated_at']
                ]);
            } else {
                echo json_encode([
                    "status" => "success",
                    "mood" => "neutral",
                    "symptoms" => [],
                    "heart_rate" => 0,
                    "context_note" => "",
                    "message" => "No mood data found"
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
// POST: Store new mood/wellness entry
// =====================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $userId = $data['user_id'] ?? 1;
    $mood = $data['mood'] ?? null;
    $symptoms = $data['symptoms'] ?? [];
    $heartRate = $data['heart_rate'] ?? null;
    $contextNote = $data['context_note'] ?? '';

    // Validation
    if ($mood === null) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Mood value required"]);
        exit;
    }

    // Valid moods from your SwiftUI enum
    // Valid moods from your SwiftUI enum - WITH SPACES
    $validMoods = ['Very Happy', 'Happy', 'Neutral', 'Sad', 'Very Sad', 'Anxious', 'Stressed'];
    if (!in_array($mood, $validMoods)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid mood value"]);
        exit;
    }


    // Process symptoms array to comma-separated string
    $symptomsString = is_array($symptoms) ? implode(',', $symptoms) : '';
    
    try {
        $stmt = $conn->prepare("UPDATE users SET 
                                latest_mood = ?, 
                                latest_symptoms = ?, 
                                latest_heart_rate = ?, 
                                latest_context_note = ?, 
                                mood_updated_at = NOW() 
                                WHERE id = ?");
        if (!$stmt) {
            echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
            exit;
        }
        $stmt->bind_param("ssisi", $mood, $symptomsString, $heartRate, $contextNote, $userId);

        if ($stmt->execute()) {
            echo json_encode([
                "status" => "success",
                "mood" => $mood,
                "symptoms" => $symptoms,
                "heart_rate" => (int)$heartRate,
                "context_note" => $contextNote,
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
?>
