<?php
/**
 * api/config/cors.php
 *
 * Sets CORS headers so the Flutter mobile app (and any cross-origin client)
 * can reach this API. Include at the very top of every endpoint before any
 * other output or headers are sent.
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');

// Flutter (and browsers) send an OPTIONS preflight before the real request.
// Respond immediately with 200 so the preflight is never blocked.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
