<?php
// daily_risk_assessment.php

ini_set('display_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require 'config.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

// Validate user_id
$user_id = $_GET['user_id'] ?? null;
if (!$user_id || !is_numeric($user_id) || intval($user_id) <= 0) {
    http_response_code(400);
    echo json_encode(["status"=>"error","message"=>"Valid user_id required"]);
    exit;
}
$user_id = intval($user_id);

// RMSSD HRV function (40–200 bpm filter, cap 150 ms)
function calculateHRVFromBPM(array $bpmValues): ?float {
    $filtered = array_filter($bpmValues, fn($b)=> $b>=40 && $b<=200);
    if (count($filtered) < 2) return null;
    $rr = array_map(fn($b)=>60000.0/$b, array_values($filtered));
    $diffs = [];
    for ($i=1,$n=count($rr); $i<$n; $i++) {
        $d = $rr[$i]-$rr[$i-1];
        $diffs[] = $d*$d;
    }
    if (empty($diffs)) return null;
    $rmssd = sqrt(array_sum($diffs)/count($diffs));
    return round(min($rmssd,150.0),2);
}

// Fetch today’s readings
$today = date('Y-m-d');
$stmt = $conn->prepare("
    SELECT bpm 
    FROM hr 
    WHERE user_id=? AND DATE(created_at)=?
    ORDER BY created_at
");
$stmt->bind_param("is",$user_id,$today);
$stmt->execute();
$res = $stmt->get_result();
$bpmValues = [];
while ($r=$res->fetch_assoc()) {
    $bpmValues[] = floatval($r['bpm']);
}
$stmt->close();

// If no readings, error
if (empty($bpmValues)) {
    echo json_encode(["status"=>"error","message"=>"No readings for today"]);
    exit;
}

// Summaries
$avg_bpm = round(array_sum($bpmValues)/count($bpmValues),1);
$max_bpm = intval(max($bpmValues));
$min_bpm = intval(min($bpmValues));
$range   = $max_bpm - $min_bpm;
$hrv     = calculateHRVFromBPM($bpmValues);

// Risk scoring (updated thresholds to be inclusive)
$risk_score = 0;
$factors = [];
$reco = [];

$rules = [
    ['v'=>$avg_bpm,'cond'=>fn($v)=> $v>=100,'pts'=>20,'f'=>"Elevated HR (≥100 bpm)","r"=>"Cardio evaluation"],
    ['v'=>$avg_bpm,'cond'=>fn($v)=> $v>=90,'pts'=>12,'f'=>"Moderately elevated HR (90–99 bpm)","r"=>"Monitor HR trends"],
    ['v'=>$avg_bpm,'cond'=>fn($v)=> $v>=85,'pts'=>8,'f'=>"Slightly elevated HR (85–89 bpm)","r"=>"Maintain exercise"],
    ['v'=>$avg_bpm,'cond'=>fn($v)=> $v<=50,'pts'=>15,'f'=>"Very low HR (≤50 bpm)","r"=>"Consult provider"],
    ['v'=>$avg_bpm,'cond'=>fn($v)=> $v<=60,'pts'=>3,'f'=>"Low HR (51–60 bpm)","r"=>"Monitor bradycardia"],

    ['v'=>$max_bpm,'cond'=>fn($v)=> $v>150,'pts'=>12,'f'=>"High peak HR (>150)","r"=>"Review exercise"],
    ['v'=>$range,'cond'=>fn($v)=> $v>=60,'pts'=>8,'f'=>"High HR range (≥60)","r"=>"Check rhythms"],
    ['v'=>$range,'cond'=>fn($v)=> $v<=10,'pts'=>4,'f'=>"Low HR range (≤10)","r"=>"Stress management"],
];

foreach ($rules as $r) {
    if ($r['cond']($r['v'])) {
        $risk_score += $r['pts'];
        $factors[] = $r['f'];
        $reco[] = $r['r'];
    }
}

// HRV scoring (unchanged)
if ($hrv !== null) {
    if ($hrv<=20) {
        $risk_score+=12; $factors[]="Very low HRV (≤20 ms)"; $reco[]="Stress management";
    } elseif ($hrv<=30) {
        $risk_score+=8; $factors[]="Low HRV (21–30 ms)"; $reco[]="Stress reduction";
    } elseif ($hrv>100) {
        $risk_score+=8; $factors[]="Unusually high HRV (>100 ms)"; $reco[]="Verify accuracy";
    }
}

// Determine level
$risk_level = match(true){
    $risk_score>=60=>"Very High",
    $risk_score>=40=>"High",
    $risk_score>=20=>"Moderate",
    default=>"Low"
};

// Defaults
if (empty($reco)) { $reco=["Maintain healthy lifestyle","Monitor vitals"]; }
if ($risk_level==="Low") { $reco[]="Keep up the good work"; }
else { $reco[]="Follow up with provider"; }

echo json_encode([
    "status"=>"success",
    "date"=>$today,
    "avg_bpm"=>$avg_bpm,
    "min_bpm"=>$min_bpm,
    "max_bpm"=>$max_bpm,
    "hrv_rmssd_ms"=>$hrv,
    "risk_score"=>$risk_score,
    "risk_level"=>$risk_level,
    "factors"=>$factors,
    "recommendations"=>$reco
]);
$conn->close();
