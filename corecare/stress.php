<?php
// Enable error reporting for debugging (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Include config file with error checking
if (!file_exists('config.php')) {
    echo json_encode(["status" => "error", "message" => "Config file not found"]);
    exit;
}

require 'config.php';

// Get user_id
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if ($userId <= 0) {
    echo json_encode(["status" => "error", "message" => "Invalid user_id"]);
    exit;
}

try {
    // Check database connection
    if (!isset($conn) || $conn->connect_error) {
        throw new Exception("Database connection failed: " . (isset($conn) ? $conn->connect_error : "Connection object not found"));
    }

    // Initialize variables
    $bpmValues = array();
    $currentBpm = null;
    $systolic = null;
    $diastolic = null;
    $stress_percentage = 0;
    $category = "Low";
    $avgBpm = 0;
    $baseStress = 0;

    // ----------------------------
    // Fetch Heart Rate Data
    // ----------------------------
    // Check if created_at column exists in hr table
    $checkHrColumn = $conn->query("SHOW COLUMNS FROM hr LIKE 'created_at'");
    $hrHasCreatedAt = $checkHrColumn && $checkHrColumn->num_rows > 0;
    
    if ($hrHasCreatedAt) {
        $sql = "SELECT bpm FROM hr WHERE user_id = ? ORDER BY created_at DESC LIMIT 30";
    } else {
        // Fallback: order by id or just get records for this user
        $checkHrIdColumn = $conn->query("SHOW COLUMNS FROM hr LIKE 'id'");
        $hrHasId = $checkHrIdColumn && $checkHrIdColumn->num_rows > 0;
        
        if ($hrHasId) {
            $sql = "SELECT bpm FROM hr WHERE user_id = ? ORDER BY id DESC LIMIT 30";
        } else {
            $sql = "SELECT bpm FROM hr WHERE user_id = ? LIMIT 30";
        }
    }
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Prepare failed for HR query: " . $conn->error);
    }
    
    $stmt->bind_param("i", $userId);
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed for HR query: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    
    if (!$result) {
        throw new Exception("Get result failed for HR query: " . $stmt->error);
    }

    while ($row = $result->fetch_assoc()) {
        if ($row['bpm'] && is_numeric($row['bpm'])) {
            $bpmValues[] = intval($row['bpm']);
        }
    }
    $stmt->close();

    // Get current BPM
    if (count($bpmValues) > 0) {
        $currentBpm = $bpmValues[0];
    }

    // ----------------------------
    // Fetch Blood Pressure Data
    // ----------------------------
    // First, check if created_at column exists
    $checkColumn = $conn->query("SHOW COLUMNS FROM bp LIKE 'created_at'");
    $hasCreatedAt = $checkColumn && $checkColumn->num_rows > 0;
    
    if ($hasCreatedAt) {
        $sql = "SELECT systolic, diastolic FROM bp WHERE user_id = ? ORDER BY created_at DESC LIMIT 1";
    } else {
        // Fallback: order by id or just get any record for this user
        $checkIdColumn = $conn->query("SHOW COLUMNS FROM bp LIKE 'id'");
        $hasId = $checkIdColumn && $checkIdColumn->num_rows > 0;
        
        if ($hasId) {
            $sql = "SELECT systolic, diastolic FROM bp WHERE user_id = ? ORDER BY id DESC LIMIT 1";
        } else {
            $sql = "SELECT systolic, diastolic FROM bp WHERE user_id = ? LIMIT 1";
        }
    }
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Prepare failed for BP query: " . $conn->error);
    }
    
    $stmt->bind_param("i", $userId);
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed for BP query: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    
    if ($result && $row = $result->fetch_assoc()) {
        if ($row['systolic'] && is_numeric($row['systolic'])) {
            $systolic = intval($row['systolic']);
        }
        if ($row['diastolic'] && is_numeric($row['diastolic'])) {
            $diastolic = intval($row['diastolic']);
        }
    }
    $stmt->close();

    // ----------------------------
    // Calculate Stress if we have BPM data
    // ----------------------------
    if (count($bpmValues) > 0) {
        // Calculate basic metrics
        $avgBpm = array_sum($bpmValues) / count($bpmValues);
        $maxBpm = max($bpmValues);
        $minBpm = min($bpmValues);
        
        // 1. Current BPM stress factor (0-50 points)
        if ($currentBpm >= 120) {
            $baseStress += 50;
        } elseif ($currentBpm >= 100) {
            $baseStress += 35;
        } elseif ($currentBpm >= 90) {
            $baseStress += 25;
        } elseif ($currentBpm >= 80) {
            $baseStress += 15;
        } elseif ($currentBpm >= 70) {
            $baseStress += 5;
        }
        
        // 2. Average BPM trend (0-25 points)
        if ($avgBpm >= 100) {
            $baseStress += 25;
        } elseif ($avgBpm >= 90) {
            $baseStress += 18;
        } elseif ($avgBpm >= 80) {
            $baseStress += 12;
        } elseif ($avgBpm >= 75) {
            $baseStress += 6;
        }
        
        // 3. Blood pressure factor (0-15 points)
        if ($systolic !== null && $diastolic !== null) {
            if ($systolic >= 140 || $diastolic >= 90) {
                $baseStress += 15;
            } elseif ($systolic >= 130 || $diastolic >= 85) {
                $baseStress += 10;
            } elseif ($systolic >= 120 || $diastolic >= 80) {
                $baseStress += 5;
            }
        }
        
        // 4. BPM variability (0-10 points)
        $range = $maxBpm - $minBpm;
        if ($range > 40) {
            $baseStress += 10;
        } elseif ($range > 25) {
            $baseStress += 6;
        } elseif ($range > 15) {
            $baseStress += 3;
        }
        
        // Calculate final stress percentage
        $stress_percentage = min(100, max(0, $baseStress));
        
        // Ensure minimum stress if vitals are present
        if ($stress_percentage == 0 && $currentBpm > 0) {
            $stress_percentage = max(5, min(20, $currentBpm - 55));
        }
        
        // Determine category
        if ($stress_percentage <= 25) {
            $category = "Low";
        } elseif ($stress_percentage <= 55) {
            $category = "Moderate";  
        } else {
            $category = "High";
        }
    }

    // ----------------------------
    // Return complete response
    // ----------------------------
    $response = array(
        "status" => "success",
        "stress_percentage" => round($stress_percentage, 1),
        "stress_category" => $category,
        "bpm" => $currentBpm,
        "category" => getBpmCategory($currentBpm),
        "systolic" => $systolic,
        "diastolic" => $diastolic,
        "debug_info" => array(
            "bpm_readings_count" => count($bpmValues),
            "average_bpm" => count($bpmValues) > 0 ? round($avgBpm, 1) : null,
            "bp_available" => ($systolic !== null && $diastolic !== null),
            "base_stress_score" => $baseStress,
            "user_id" => $userId
        )
    );

    echo json_encode($response);

} catch (Exception $e) {
    $errorResponse = array(
        "status" => "error", 
        "message" => $e->getMessage(),
        "line" => $e->getLine(),
        "file" => basename($e->getFile()),
        "user_id" => $userId ?? 0
    );
    
    echo json_encode($errorResponse);
}

// Helper function for BPM category
function getBpmCategory($bpm) {
    if ($bpm === null) return null;
    if ($bpm < 60) return "Low";
    if ($bpm <= 100) return "Normal";
    if ($bpm <= 120) return "Elevated";
    return "High";
}

// Close connection if it exists
if (isset($conn)) {
    $conn->close();
}
?>