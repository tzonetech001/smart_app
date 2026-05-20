<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$data = json_decode(file_get_contents('php://input'), true);

if (!$data) {
    echo json_encode(['error' => 'Invalid input']);
    exit;
}

$products = $data['products'] ?? [];
$salesHistory = $data['salesHistory'] ?? [];

// Calculate average engagement
$totalEngagement = 0;
foreach ($products as $product) {
    $totalEngagement += $product['engagementScore'] ?? 0;
}
$avgEngagement = count($products) > 0 ? $totalEngagement / count($products) : 0;

// Predict growth based on engagement
$predictedGrowth = 0;
if ($avgEngagement > 1000) {
    $predictedGrowth = 0.20;
} elseif ($avgEngagement > 500) {
    $predictedGrowth = 0.10;
} elseif ($avgEngagement > 200) {
    $predictedGrowth = 0.05;
} else {
    $predictedGrowth = -0.05;
}

// Generate recommendations
$recommendations = [];
foreach ($products as $product) {
    if (($product['engagementScore'] ?? 0) > 1000 && ($product['stock'] ?? 0) < 50) {
        $recommendations[] = [
            'productId' => $product['id'],
            'productName' => $product['name'],
            'recommendation' => 'Increase stock for ' . $product['name'],
            'priority' => 'HIGH'
        ];
    } elseif (($product['engagementScore'] ?? 0) < 200 && ($product['stock'] ?? 0) > 20) {
        $recommendations[] = [
            'productId' => $product['id'],
            'productName' => $product['name'],
            'recommendation' => 'Consider promotion or discount for ' . $product['name'],
            'priority' => 'MEDIUM'
        ];
    }
}

$response = [
    'predictedGrowth' => $predictedGrowth,
    'predictedSalesNextWeek' => round($predictedGrowth * 100) . '%',
    'demandLevel' => $predictedGrowth > 0.15 ? 'HIGH' : ($predictedGrowth > 0 ? 'MEDIUM' : 'LOW'),
    'recommendations' => $recommendations,
    'timestamp' => date('c')
];

echo json_encode($response);
?>