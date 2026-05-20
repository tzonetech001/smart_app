<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// This would normally fetch from Firebase via Admin SDK
// For demonstration, returning sample data

$trendingProducts = [
    [
        'productId' => '1',
        'productName' => 'Bajaj Motorcycle',
        'category' => 'Automobile & Transport',
        'engagementScore' => 1500,
        'trendGrowth' => 0.35,
        'trendPercentage' => '+35%'
    ],
    [
        'productId' => '2',
        'productName' => 'Smart TV',
        'category' => 'Electronics',
        'engagementScore' => 1200,
        'trendGrowth' => 0.28,
        'trendPercentage' => '+28%'
    ],
    [
        'productId' => '3',
        'productName' => 'Organic Coffee',
        'category' => 'Food & Beverages',
        'engagementScore' => 950,
        'trendGrowth' => 0.22,
        'trendPercentage' => '+22%'
    ]
];

echo json_encode([
    'trendingProducts' => $trendingProducts,
    'timestamp' => date('c')
]);
?>