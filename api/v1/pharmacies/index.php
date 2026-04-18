<?php
/**
 * api/v1/pharmacies/index.php
 *
 * GET /api/v1/pharmacies
 *
 * Public — returns all registered pharmacies (customers with user_role = 1).
 * Fields returned: customer_id, customer_name, customer_city,
 *                  customer_contact, customer_image
 *
 * Intentionally excludes email, password, and country to keep the
 * public profile lean. The Flutter app uses this to show a pharmacy
 * browser / map screen.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed. Use GET.', 405);
}

try {
    $pdo  = Database::connect();
    $stmt = $pdo->prepare(
        'SELECT customer_id, customer_name, customer_city,
                customer_contact, customer_image
         FROM customer
         WHERE user_role = ?
         ORDER BY customer_name ASC'
    );
    $stmt->execute([1]); // role 1 = Pharmacy Owner
    $pharmacies = $stmt->fetchAll();
} catch (PDOException $e) {
    error_log('Pharmacies index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success($pharmacies, count($pharmacies) . ' pharmacy/pharmacies retrieved.', 200);
