<?php
/**
 * api/v1/auth/register.php
 *
 * POST /api/v1/auth/register
 *
 * Request body (JSON):
 *   {
 *     "customer_name":    "Jane Doe",
 *     "customer_email":   "jane@example.com",
 *     "customer_pass":    "secret123",
 *     "customer_contact": "+233200000000",
 *     "customer_country": "Ghana",
 *     "customer_city":    "Accra"
 *   }
 *
 * Success response (201):
 *   { "status": "success", "data": { "customer_id": 42 } }
 *
 * New accounts are always created as user_role = 2 (Regular Customer),
 * matching the role scheme used in the existing web application.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
}

// -------------------------------------------------------------------------
// Parse and validate request body
// -------------------------------------------------------------------------
$body = json_decode(file_get_contents('php://input'), true);

$required = [
    'customer_name', 'customer_email', 'customer_pass',
    'customer_contact', 'customer_country', 'customer_city',
];

foreach ($required as $field) {
    if (!isset($body[$field]) || trim((string) $body[$field]) === '') {
        Response::error("Field '{$field}' is required.", 422);
    }
}

$name    = trim($body['customer_name']);
$email   = trim($body['customer_email']);
$pass    = $body['customer_pass'];
$contact = trim($body['customer_contact']);
$country = trim($body['customer_country']);
$city    = trim($body['customer_city']);

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    Response::error('Invalid email address.', 422);
}

// -------------------------------------------------------------------------
// Check for duplicate email
// -------------------------------------------------------------------------
try {
    $pdo  = Database::connect();
    $stmt = $pdo->prepare('SELECT customer_id FROM customer WHERE customer_email = ? LIMIT 1');
    $stmt->execute([$email]);

    if ($stmt->fetch()) {
        Response::error('An account with that email address already exists.', 409);
    }
} catch (PDOException $e) {
    error_log('Register duplicate-check error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

// -------------------------------------------------------------------------
// Insert the new customer (password hashed with PASSWORD_DEFAULT / bcrypt)
// -------------------------------------------------------------------------
try {
    $hashed = password_hash($pass, PASSWORD_DEFAULT);

    $insert = $pdo->prepare(
        'INSERT INTO customer
            (customer_name, customer_email, customer_pass, customer_contact,
             customer_country, customer_city, user_role)
         VALUES (?, ?, ?, ?, ?, ?, ?)'
    );
    $insert->execute([$name, $email, $hashed, $contact, $country, $city, 2]);

    $new_id = (int) $pdo->lastInsertId();
} catch (PDOException $e) {
    error_log('Register insert error: ' . $e->getMessage());
    Response::error('Registration failed. Please try again later.', 500);
}

Response::success(
    ['customer_id' => $new_id],
    'Registration successful. You can now log in.',
    201
);
