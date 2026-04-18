<?php
/**
 * api/v1/brands/index.php
 *
 * GET /api/v1/brands
 *
 * Public — returns all brands platform-wide.
 * Optional query parameter:
 *   cat_id — filter brands that belong to a specific category
 *
 * Each row includes cat_name from the joined categories table so the Flutter
 * app can display "Panadol (Pain Relief)" style labels without a second call.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed. Use GET.', 405);
}

$cat_id = isset($_GET['cat_id']) && ctype_digit($_GET['cat_id']) ? (int) $_GET['cat_id'] : null;

try {
    $pdo = Database::connect();

    if ($cat_id !== null) {
        $stmt = $pdo->prepare(
            'SELECT b.brand_id, b.brand_name, b.cat_id, b.brand_description,
                    b.created_at, c.cat_name
             FROM brands b
             INNER JOIN categories c ON b.cat_id = c.cat_id
             WHERE b.cat_id = ?
             ORDER BY b.brand_name ASC'
        );
        $stmt->execute([$cat_id]);
    } else {
        $stmt = $pdo->query(
            'SELECT b.brand_id, b.brand_name, b.cat_id, b.brand_description,
                    b.created_at, c.cat_name
             FROM brands b
             INNER JOIN categories c ON b.cat_id = c.cat_id
             ORDER BY c.cat_name ASC, b.brand_name ASC'
        );
    }

    $brands = $stmt->fetchAll();
} catch (PDOException $e) {
    error_log('Brands index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success($brands, count($brands) . ' brand(s) retrieved.', 200);
