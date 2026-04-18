<?php
/**
 * router.php — PHP built-in server router
 *
 * Start the API server from the project root:
 *   php -S 0.0.0.0:8080 router.php
 *
 * In your Flutter app (api_constants.dart) set:
 *   static const String _host = 'http://10.0.2.2:8080';   // Android emulator
 *   static const String _host = 'http://192.168.x.x:8080'; // physical device
 *
 * Routes clean URLs like /api/v1/auth/login
 * to PHP files like    api/v1/auth/login.php
 */

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = rawurldecode($uri);

// Serve real files (uploads/prescriptions/..., vendor assets, etc.)
if ($uri !== '/' && file_exists(__DIR__ . $uri)) {
    return false; // let the built-in server handle static files
}

// Try   /api/v1/auth/login  →  api/v1/auth/login.php
$phpFile = __DIR__ . rtrim($uri, '/') . '.php';
if (file_exists($phpFile)) {
    require $phpFile;
    return true;
}

// Try   /api/v1/cart  →  api/v1/cart/index.php
$indexFile = __DIR__ . '/' . trim($uri, '/') . '/index.php';
if (file_exists($indexFile)) {
    require $indexFile;
    return true;
}

header('Content-Type: application/json');
http_response_code(404);
echo json_encode([
    'status'  => 'error',
    'message' => 'Endpoint not found: ' . $uri,
    'data'    => null,
]);
