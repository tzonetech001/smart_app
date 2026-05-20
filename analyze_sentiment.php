<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['comment'])) {
    echo json_encode(['error' => 'Invalid input']);
    exit;
}

$comment = strtolower($data['comment']);

$positiveWords = ['good', 'great', 'excellent', 'amazing', 'love', 'best', 'perfect', 'nice', 'awesome', 'wonderful'];
$negativeWords = ['bad', 'poor', 'terrible', 'hate', 'worst', 'awful', 'disappointing', 'horrible'];

$positiveCount = 0;
$negativeCount = 0;

foreach ($positiveWords as $word) {
    if (strpos($comment, $word) !== false) {
        $positiveCount++;
    }
}

foreach ($negativeWords as $word) {
    if (strpos($comment, $word) !== false) {
        $negativeCount++;
    }
}

$sentiment = 'neutral';
$confidence = 0.7;

if ($positiveCount > $negativeCount) {
    $sentiment = 'positive';
    $confidence = min(0.5 + ($positiveCount * 0.1), 0.95);
} elseif ($negativeCount > $positiveCount) {
    $sentiment = 'negative';
    $confidence = min(0.5 + ($negativeCount * 0.1), 0.95);
}

$response = [
    'sentiment' => $sentiment,
    'confidence' => $confidence,
    'positiveWords' => $positiveCount,
    'negativeWords' => $negativeCount,
    'timestamp' => date('c')
];

echo json_encode($response);
?>