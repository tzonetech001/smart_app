<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

$data = json_decode(file_get_contents('php://input'), true);

$productId = $data['productId'] ?? null;
$salesHistory = $data['salesHistory'] ?? [];

if (!$productId) {
    echo json_encode(['error' => 'Product ID required']);
    exit;
}

// Simple moving average forecasting
$forecast = [];
if (count($salesHistory) >= 7) {
    $lastWeekSales = array_slice($salesHistory, -7);
    $averageSales = array_sum($lastWeekSales) / 7;
    $forecast = [
        'nextWeek' => round($averageSales * 1.1, 2),
        'nextMonth' => round($averageSales * 4.5, 2),
        'growthRate' => 0.10,
        'confidence' => 0.85
    ];
} else {
    $forecast = [
        'nextWeek' => 0,
        'nextMonth' => 0,
        'growthRate' => 0,
        'confidence' => 0.5,
        'message' => 'Insufficient data for accurate forecast'
    ];
}

echo json_encode([
    'productId' => $productId,
    'forecast' => $forecast,
    'timestamp' => date('c')
]);
?>