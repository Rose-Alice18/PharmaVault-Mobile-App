<?php
/**
 * api/v1/auth/login.php
 *
 * POST /api/v1/auth/login
 *
 * Request body (JSON):
 *   { "email": "user@example.com", "password": "secret" }
 *
 * Success response (200):
 *   { "status": "success", "data": { "token": "...", "customer_id": 1, ... } }
 *
 * This endpoint is public — it issues the token, so it does not go through
 * auth_middleware.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../../vendor/autoload.php'; // firebase/php-jwt

use Firebase\JWT\JWT;

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
}

// -------------------------------------------------------------------------
// Parse JSON body
// -------------------------------------------------------------------------
$body = json_decode(file_get_contents('php://input'), true);

if (empty($body['email']) || empty($body['password'])) {
    Response::error('Both email and password are required.', 422);
}

$email    = trim($body['email']);
$password = $body['password'];

// -------------------------------------------------------------------------
// Look up the customer by email
// -------------------------------------------------------------------------
try {
    $pdo  = Database::connect();
    $stmt = $pdo->prepare(
        'SELECT customer_id, customer_name, customer_email, customer_pass, user_role
         FROM customer
         WHERE customer_email = ?
         LIMIT 1'
    );
    $stmt->execute([$email]);
    $customer = $stmt->fetch();
} catch (PDOException $e) {
    error_log('Login DB error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

// -------------------------------------------------------------------------
// Verify password (hashed with password_hash in the web app)
// -------------------------------------------------------------------------
if (!$customer || !password_verify($password, $customer['customer_pass'])) {
    Response::error('Invalid email or password.', 401);
}

// -------------------------------------------------------------------------
// Issue a signed JWT
// -------------------------------------------------------------------------
$now = time();
$payload = [
    'iat'           => $now,
    'exp'           => $now + JWT_EXPIRY,
    'customer_id'   => (int) $customer['customer_id'],
    'user_role'     => (int) $customer['user_role'],
    'customer_name' => $customer['customer_name'],
];

$token = JWT::encode($payload, JWT_SECRET, 'HS256');

Response::success(
    [
        'token'          => $token,
        'expires_in'     => JWT_EXPIRY,
        'customer_id'    => (int) $customer['customer_id'],
        'customer_name'  => $customer['customer_name'],
        'customer_email' => $customer['customer_email'],
        'user_role'      => (int) $customer['user_role'],
    ],
    'Login successful.',
    200
);
