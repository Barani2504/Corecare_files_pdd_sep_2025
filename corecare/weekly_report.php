<?php
// weekly_report.php - FIXED VERSION
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

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

function calculateHRVFromBPM($bpmValues) {
    if (count($bpmValues) < 2) return null;
    
    // Filter out outliers and invalid values
    $filteredBPM = array_filter($bpmValues, function($bpm) {
        return $bpm >= 40 && $bpm <= 200; // Reasonable HR range
    });
    
    if (count($filteredBPM) < 2) return null;
    
    // Convert BPM to RR intervals in milliseconds
    $rrIntervals = [];
    foreach ($filteredBPM as $bpm) {
        $rrIntervals[] = 60000 / $bpm;
    }
    
    // Calculate RMSSD (Root Mean Square of Successive Differences)
    // This is more appropriate for short-term HRV
    $differences = [];
    for ($i = 1; $i < count($rrIntervals); $i++) {
        $differences[] = $rrIntervals[$i] - $rrIntervals[$i-1];
    }
    
    if (empty($differences)) return null;
    
    $squaredDiffs = array_map(function($diff) {
        return $diff * $diff;
    }, $differences);
    
    $rmssd = sqrt(array_sum($squaredDiffs) / count($squaredDiffs));
    
    // Cap HRV at reasonable values (typical range is 20-100ms for RMSSD)
    $rmssd = min($rmssd, 150);
    
    return round($rmssd, 2);
}

function getRestingHeartRate($bpmValues) {
    if (empty($bpmValues)) return null;
    
    // Filter reasonable values
    $filtered = array_filter($bpmValues, function($bpm) {
        return $bpm >= 40 && $bpm <= 100; // Typical resting range
    });
    
    if (empty($filtered)) return null;
    
    sort($filtered);
    $percentile20 = max(1, intval(count($filtered) * 0.2));
    return round(array_sum(array_slice($filtered, 0, $percentile20)) / $percentile20, 1);
}

try {
    $week_start = date('Y-m-d', strtotime('-6 days'));
    $today = date('Y-m-d');

    // HR Summary - filter outliers
    $stmt_hr = $conn->prepare("
        SELECT AVG(bpm) as avg_bpm, MIN(bpm) as min_bpm, MAX(bpm) as max_bpm 
        FROM hr 
        WHERE user_id=? AND DATE(created_at) BETWEEN ? AND ? 
        AND bpm BETWEEN 40 AND 200");
    $stmt_hr->bind_param("iss", $user_id, $week_start, $today);
    $stmt_hr->execute();
    $hr = $stmt_hr->get_result()->fetch_assoc();

    // BPM values for HRV - get only reasonable values
    $stmt_bpm = $conn->prepare("
        SELECT bpm FROM hr 
        WHERE user_id=? AND DATE(created_at) BETWEEN ? AND ? 
        AND bpm BETWEEN 40 AND 200
        ORDER BY created_at");
    $stmt_bpm->bind_param("iss", $user_id, $week_start, $today);
    $stmt_bpm->execute();
    $bpm_res = $stmt_bpm->get_result();
    $bpmValues = [];
    while ($row = $bpm_res->fetch_assoc()) {
        $bpmValues[] = floatval($row['bpm']);
    }

    // BP summary
    $stmt_bp = $conn->prepare("
        SELECT AVG(systolic) as avg_systolic, AVG(diastolic) as avg_diastolic 
        FROM bp 
        WHERE user_id=? AND DATE(recorded_at) BETWEEN ? AND ?
        AND systolic BETWEEN 70 AND 250 
        AND diastolic BETWEEN 40 AND 150");
    $stmt_bp->bind_param("iss", $user_id, $week_start, $today);
    $stmt_bp->execute();
    $bp = $stmt_bp->get_result()->fetch_assoc();

    // Daily readings
    $stmt_daily = $conn->prepare("
        SELECT DATE(created_at) as date, AVG(bpm) as avg_bpm, COUNT(*) as count
        FROM hr 
        WHERE user_id=? AND DATE(created_at) BETWEEN ? AND ?
        AND bpm BETWEEN 40 AND 200
        GROUP BY DATE(created_at) ORDER BY date ASC");
    $stmt_daily->bind_param("iss", $user_id, $week_start, $today);
    $stmt_daily->execute();
    $daily_res = $stmt_daily->get_result();
    $daily_readings = [];
    
    while ($row = $daily_res->fetch_assoc()) {
        $date = $row['date'];
        
        // BP for date with validation
        $stmt_bp_day = $conn->prepare("
            SELECT AVG(systolic) as sys, AVG(diastolic) as dia 
            FROM bp 
            WHERE user_id=? AND DATE(recorded_at)=?
            AND systolic BETWEEN 70 AND 250 
            AND diastolic BETWEEN 40 AND 150");
        $stmt_bp_day->bind_param("is", $user_id, $date);
        $stmt_bp_day->execute();
        $bp_day = $stmt_bp_day->get_result()->fetch_assoc();

        // BPM for HRV with validation
        $stmt_bpm_day = $conn->prepare("
            SELECT bpm FROM hr 
            WHERE user_id=? AND DATE(created_at)=? 
            AND bpm BETWEEN 40 AND 200
            ORDER BY created_at");
        $stmt_bpm_day->bind_param("is", $user_id, $date);
        $stmt_bpm_day->execute();
        $bpm_day_res = $stmt_bpm_day->get_result();
        $day_bpm_vals = [];
        while ($row_bpm = $bpm_day_res->fetch_assoc()) {
            $day_bpm_vals[] = floatval($row_bpm['bpm']);
        }
        $day_hrv = calculateHRVFromBPM($day_bpm_vals);
        $stmt_bp_day->close();
        $stmt_bpm_day->close();

        $daily_readings[] = [
            "date" => $date,
            "avg_bpm" => round(floatval($row['avg_bpm']), 1),
            "avg_systolic" => intval(round(floatval($bp_day['sys'] ?? 0))),
            "avg_diastolic" => intval(round(floatval($bp_day['dia'] ?? 0))),
            "measurement_count" => intval($row['count']),
            "hrv" => $day_hrv
        ];
    }

    // Weekly HRV and rest HR
    $weekly_hrv = calculateHRVFromBPM($bpmValues);
    $weekly_resting_hr = getRestingHeartRate($bpmValues);

    $response = [
        "status" => "success",
        "weekly_summary" => [
            "avg_bpm" => round(floatval($hr['avg_bpm'] ?? 0), 1),
            "min_bpm" => intval($hr['min_bpm'] ?? 0),
            "max_bpm" => intval($hr['max_bpm'] ?? 0),
            "avg_bp_systolic" => intval(round(floatval($bp['avg_systolic'] ?? 0))),
            "avg_bp_diastolic" => intval(round(floatval($bp['avg_diastolic'] ?? 0))),
            "avg_hrv" => $weekly_hrv,
            "resting_heart_rate" => $weekly_resting_hr,
            "recovery_heart_rate" => null,
            "measurement_count" => count($bpmValues)
        ],
        "daily_readings" => $daily_readings
    ];

    echo json_encode($response);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Failed to generate weekly report"]);
} finally {
    if ($conn) $conn->close();
}
?>