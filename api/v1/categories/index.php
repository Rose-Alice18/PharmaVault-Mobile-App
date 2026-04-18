<?php
/**
 * api/v1/categories/index.php
 *
 * GET /api/v1/categories
 *
 * Public — returns all product categories platform-wide.
 * No JWT required so the Flutter app can show the category list
 * on browse/search screens before the user logs in.
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
    $stmt = $pdo->query(
        'SELECT cat_id, cat_name, cat_description, created_at
         FROM categories
         ORDER BY cat_name ASC'
    );
    $categories = $stmt->fetchAll();
} catch (PDOException $e) {
    error_log('Categories index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success($categories, count($categories) . ' category/categories retrieved.', 200);
