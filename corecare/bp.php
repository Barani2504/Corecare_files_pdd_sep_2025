<?php
// manual_bp_calc.php - Manual Blood Pressure Calculation API
// ⚠️ DISCLAIMER: FOR EDUCATIONAL PURPOSES ONLY
// This is NOT a substitute for actual medical devices or professional medical advice

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Manual BP calculation with step-by-step process
function manualCalculateBPFromBpm($bpm, $userId = null) {
    // Step 1: Validate and clamp heart rate
    $original_bpm = $bpm;
    $bpm = max(40, min(180, $bpm));
    
    $steps = [];
    $steps[] = "Step 1: Heart rate validation - Input: {$original_bpm} BPM, Clamped: {$bpm} BPM";
    
    // Step 2: Determine base physiological state
    $resting_hr = 70;
    $base_systolic = 120;
    $base_diastolic = 80;
    
    $steps[] = "Step 2: Base values - Resting HR: {$resting_hr}, Base BP: {$base_systolic}/{$base_diastolic}";
    
    // Step 3: Calculate HR deviation and physiological response
    $hr_deviation = $bpm - $resting_hr;
    $steps[] = "Step 3: HR deviation from resting = {$hr_deviation} BPM";
    
    // Step 4: Manual calculation based on physiological principles
    if ($bpm < 50) {
        // Severe bradycardia - compensatory mechanisms
        $systolic_adjustment = -25 + ($bpm - 40) * 0.5;
        $diastolic_adjustment = -15 + ($bpm - 40) * 0.3;
        $condition = "Severe Bradycardia";
        $steps[] = "Step 4a: Severe bradycardia detected - applying compensatory adjustments";
    } elseif ($bpm < 60) {
        // Mild bradycardia
        $systolic_adjustment = -15 + ($bpm - 50) * 1.0;
        $diastolic_adjustment = -10 + ($bpm - 50) * 0.5;
        $condition = "Mild Bradycardia";
        $steps[] = "Step 4b: Mild bradycardia - reduced cardiac output compensation";
    } elseif ($bpm <= 100) {
        // Normal range - linear relationship
        $systolic_adjustment = $hr_deviation * 0.4;
        $diastolic_adjustment = $hr_deviation * 0.2;
        $condition = "Normal Range";
        $steps[] = "Step 4c: Normal HR range - linear BP adjustment";
    } elseif ($bpm <= 120) {
        // Mild tachycardia
        $excess_hr = $bpm - 100;
        $systolic_adjustment = 12 + ($excess_hr * 0.8);
        $diastolic_adjustment = 4 + ($excess_hr * 0.4);
        $condition = "Mild Tachycardia";
        $steps[] = "Step 4d: Mild tachycardia - increased cardiac output";
    } elseif ($bpm <= 150) {
        // Moderate tachycardia
        $excess_hr = $bpm - 100;
        $systolic_adjustment = 16 + ($excess_hr * 0.6);
        $diastolic_adjustment = 8 + ($excess_hr * 0.3);
        $condition = "Moderate Tachycardia";
        $steps[] = "Step 4e: Moderate tachycardia - significant cardiovascular stress";
    } else {
        // Severe tachycardia
        $excess_hr = $bpm - 100;
        $systolic_adjustment = 20 + ($excess_hr * 0.4);
        $diastolic_adjustment = 10 + ($excess_hr * 0.2);
        $condition = "Severe Tachycardia";
        $steps[] = "Step 4f: Severe tachycardia - maximum cardiovascular response";
    }
    
    // Step 5: Apply adjustments
    $calculated_systolic = $base_systolic + $systolic_adjustment;
    $calculated_diastolic = $base_diastolic + $diastolic_adjustment;
    
    $steps[] = "Step 5: Raw calculations - Systolic: {$base_systolic} + {$systolic_adjustment} = {$calculated_systolic}";
    $steps[] = "Step 5: Raw calculations - Diastolic: {$base_diastolic} + {$diastolic_adjustment} = {$calculated_diastolic}";
    
    // Step 6: Apply physiological limits and rounding
    $final_systolic = max(85, min(200, round($calculated_systolic)));
    $final_diastolic = max(50, min(130, round($calculated_diastolic)));
    
    // Step 7: Ensure diastolic is lower than systolic
    if ($final_diastolic >= $final_systolic) {
        $final_diastolic = $final_systolic - 20;
    }
    
    $steps[] = "Step 6: Applied physiological limits - Final BP: {$final_systolic}/{$final_diastolic}";
    
    // Step 8: Calculate additional metrics
    $pulse_pressure = $final_systolic - $final_diastolic;
    $mean_arterial_pressure = round($final_diastolic + ($pulse_pressure / 3));
    
    $steps[] = "Step 7: Calculated metrics - Pulse Pressure: {$pulse_pressure}, MAP: {$mean_arterial_pressure}";
    
    // Step 9: Confidence calculation based on HR range
    if ($bpm >= 60 && $bpm <= 100) {
        $confidence = 0.95;
    } elseif ($bpm >= 50 && $bpm <= 120) {
        $confidence = 0.85;
    } elseif ($bpm >= 40 && $bpm <= 150) {
        $confidence = 0.75;
    } else {
        $confidence = 0.60;
    }
    
    $steps[] = "Step 8: Confidence assessment - {$confidence} based on HR range";
    
    return [
        'systolic' => $final_systolic,
        'diastolic' => $final_diastolic,
        'pulse_pressure' => $pulse_pressure,
        'mean_arterial_pressure' => $mean_arterial_pressure,
        'confidence' => $confidence,
        'physiological_condition' => $condition,
        'calculation_steps' => $steps,
        'raw_calculations' => [
            'hr_deviation' => $hr_deviation,
            'systolic_adjustment' => round($systolic_adjustment, 2),
            'diastolic_adjustment' => round($diastolic_adjustment, 2)
        ]
    ];
}

// Enhanced BP category classification
function getBpCategoryDetailed($systolic, $diastolic) {
    if ($systolic < 120 && $diastolic < 80) {
        return [
            'category' => 'Normal',
            'risk_score' => 0.1,
            'recommendation' => 'Maintain healthy lifestyle: regular exercise, balanced diet, adequate sleep.'
        ];
    } elseif ($systolic >= 120 && $systolic <= 129 && $diastolic < 80) {
        return [
            'category' => 'Elevated',
            'risk_score' => 0.25,
            'recommendation' => 'Lifestyle modifications: reduce sodium intake, increase physical activity, manage stress.'
        ];
    } elseif (($systolic >= 130 && $systolic <= 139) || ($diastolic >= 80 && $diastolic <= 89)) {
        return [
            'category' => 'Hypertension Stage 1',
            'risk_score' => 0.4,
            'recommendation' => 'Lifestyle changes and regular monitoring. Consider medical consultation.'
        ];
    } elseif ($systolic >= 140 || $diastolic >= 90) {
        if ($systolic > 180 || $diastolic > 120) {
            return [
                'category' => 'Hypertensive Crisis',
                'risk_score' => 0.95,
                'recommendation' => 'IMMEDIATE medical attention required - potential medical emergency.'
            ];
        } else {
            return [
                'category' => 'Hypertension Stage 2',
                'risk_score' => 0.7,
                'recommendation' => 'Medical evaluation and treatment likely needed. Monitor closely.'
            ];
        }
    }
    return [
        'category' => 'Indeterminate',
        'risk_score' => 0.5,
        'recommendation' => 'Consult healthcare provider for proper assessment.'
    ];
}

// GET method - Return latest calculated BP with manual process
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $userId = $_GET['user_id'] ?? null;

    if (!$userId || !is_numeric($userId)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Valid user_id is required",
            "error_code" => "INVALID_USER_ID"
        ]);
        exit;
    }

    $sql = "SELECT bpm, created_at FROM hr WHERE user_id = ? ORDER BY created_at DESC LIMIT 1";
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        echo json_encode([
            "status" => "error",
            "message" => "Database preparation failed: " . $conn->error,
            "error_code" => "DB_PREPARE_FAILED"
        ]);
        exit;
    }

    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        $bpm = 72; // realistic resting baseline
        $data_source = 'baseline_estimation';
        $measurement_time = null;
    } else {
        $row = $result->fetch_assoc();
        $bpm = (int)$row['bpm'];
        $data_source = 'latest_measurement';
        $measurement_time = $row['created_at'];
    }

    $bpData = manualCalculateBPFromBpm($bpm, $userId);
    $categoryInfo = getBpCategoryDetailed($bpData['systolic'], $bpData['diastolic']);

    $response = [
        "status" => "success",
        "data" => array_merge($bpData, [
            'category' => $categoryInfo['category'],
            'risk_score' => $categoryInfo['risk_score'],
            'recommendation' => $categoryInfo['recommendation'],
            'data_source' => $data_source,
            'measurement_time' => $measurement_time,
            'input_bpm' => $bpm
        ]),
        "disclaimer" => "⚠️ FOR EDUCATIONAL PURPOSES ONLY. Manual calculation based on physiological principles, not actual BP measurement.",
        "timestamp" => date('Y-m-d H:i:s'),
        "api_version" => "2.0.0"
    ];

    echo json_encode($response, JSON_PRETTY_PRINT);
    $stmt->close();
    $conn->close();
    exit;
}

// POST method - Manual calculate BP from provided BPM
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;

    $userId = $input['user_id'] ?? null;
    $bpm = $input['bpm'] ?? null;

    if (!$userId || !is_numeric($userId)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Valid user_id is required",
            "error_code" => "INVALID_USER_ID"
        ]);
        exit;
    }

    if (!$bpm || !is_numeric($bpm) || $bpm < 30 || $bpm > 200) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Valid bpm is required (30-200 range)",
            "error_code" => "INVALID_BPM"
        ]);
        exit;
    }

    $bpm = (int)$bpm;
    $bpData = manualCalculateBPFromBpm($bpm, $userId);
    $categoryInfo = getBpCategoryDetailed($bpData['systolic'], $bpData['diastolic']);

    $response = [
        "status" => "success",
        "message" => "Manual BP calculation completed with step-by-step process",
        "data" => array_merge($bpData, [
            'category' => $categoryInfo['category'],
            'risk_score' => $categoryInfo['risk_score'],
            'recommendation' => $categoryInfo['recommendation']
        ]),
        "input_parameters" => [
            "user_id" => $userId,
            "input_bpm" => $bpm
        ],
        "disclaimer" => "⚠️ EDUCATIONAL PURPOSES ONLY. Manual physiological calculation, not actual medical measurement.",
        "timestamp" => date('Y-m-d H:i:s'),
        "api_version" => "2.0.0"
    ];

    echo json_encode($response, JSON_PRETTY_PRINT);
    $conn->close();
    exit;
}

// Method not allowed
http_response_code(405);
echo json_encode([
    "status" => "error",
    "message" => "Method not allowed",
    "allowed_methods" => ["GET", "POST", "OPTIONS"],
    "error_code" => "METHOD_NOT_ALLOWED"
]);

if (isset($conn)) $conn->close();
?>
