<?php
// daily_report.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require 'config.php';

// CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

// Validate user_id
$user_id = $_GET['user_id'] ?? null;
if (!$user_id || !is_numeric($user_id) || $user_id <= 0) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Valid user_id is required"]);
    exit;
}
$user_id = intval($user_id);

if (!$conn) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit;
}

// Functions for HRV and Resting HR
function calculateHRVFromBPM($bpmValues) {
    if (count($bpmValues) < 2) return null;
    $rrs = [];
    foreach ($bpmValues as $bpm) {
        if ($bpm > 0) $rrs[] = 60000 / $bpm;
    }
    if (count($rrs) < 2) return null;
    $mean = array_sum($rrs) / count($rrs);
    $squaredDiffs = array_map(function($rr) use ($mean) { return pow($rr - $mean, 2); }, $rrs);
    return round(sqrt(array_sum($squaredDiffs) / (count($rrs) - 1)), 2);
}

function getRestingHeartRate($bpmValues) {
    if (empty($bpmValues)) return null;
    sort($bpmValues);
    $percentile20 = max(1, intval(count($bpmValues) * 0.2));
    $slice = array_slice($bpmValues, 0, $percentile20);
    return round(array_sum($slice) / count($slice), 1);
}

try {
    $today = date('Y-m-d');

    // Heart Rate Summary
    $stmt_hr = $conn->prepare("SELECT AVG(bpm) as avg_bpm, MIN(bpm) as min_bpm, MAX(bpm) as max_bpm FROM hr WHERE user_id=? AND DATE(created_at)=?");
    $stmt_hr->bind_param("is", $user_id, $today);
    $stmt_hr->execute();
    $hr = $stmt_hr->get_result()->fetch_assoc();

    // BPM array for HRV & Resting HR
    $stmt_bpm = $conn->prepare("SELECT bpm FROM hr WHERE user_id=? AND DATE(created_at)=? ORDER BY created_at");
    $stmt_bpm->bind_param("is", $user_id, $today);
    $stmt_bpm->execute();
    $bpm_result = $stmt_bpm->get_result();
    $bpmValues = [];
    while ($row = $bpm_result->fetch_assoc()) {
        $bpmValues[] = floatval($row['bpm']);
    }

    // BP Summary
    $stmt_bp = $conn->prepare("SELECT AVG(systolic) as avg_systolic, AVG(diastolic) as avg_diastolic FROM bp WHERE user_id=? AND DATE(recorded_at)=?");
    $stmt_bp->bind_param("is", $user_id, $today);
    $stmt_bp->execute();
    $bp = $stmt_bp->get_result()->fetch_assoc();

    // Counts
    $stmt_count = $conn->prepare("SELECT COUNT(*) as count FROM hr WHERE user_id=? AND DATE(created_at)=?");
    $stmt_count->bind_param("is", $user_id, $today);
    $stmt_count->execute();
    $count = $stmt_count->get_result()->fetch_assoc();

    // HRV and Resting HR
    $hrv = calculateHRVFromBPM($bpmValues);
    $resting_hr = getRestingHeartRate($bpmValues);

    $response = [
        "status" => "success",
        "weekly_summary" => [
            "avg_bpm" => round(floatval($hr['avg_bpm'] ?? 0), 1),
            "min_bpm" => intval($hr['min_bpm'] ?? 0),
            "max_bpm" => intval($hr['max_bpm'] ?? 0),
            "avg_bp_systolic" => intval(round(floatval($bp['avg_systolic'] ?? 0))),
            "avg_bp_diastolic" => intval(round(floatval($bp['avg_diastolic'] ?? 0))),
            "avg_hrv" => $hrv,
            "resting_heart_rate" => $resting_hr,
            "recovery_heart_rate" => null
        ],
        "daily_readings" => [
            [
                "date" => $today,
                "avg_bpm" => round(floatval($hr['avg_bpm'] ?? 0), 1),
                "avg_systolic" => intval(round(floatval($bp['avg_systolic'] ?? 0))),
                "avg_diastolic" => intval(round(floatval($bp['avg_diastolic'] ?? 0))),
                "measurement_count" => intval($count['count'] ?? 0),
                "hrv" => $hrv
            ]
        ]
    ];
    echo json_encode($response);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Failed to generate daily report"]);
} finally {
    if ($conn) $conn->close();
}
?>
