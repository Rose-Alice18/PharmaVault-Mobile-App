<?php
/**
 * api/v1/products/index.php
 *
 * GET /api/v1/products
 *
 * Protected — requires a valid JWT Bearer token.
 *
 * Optional query parameters:
 *   search   – searches product_title, product_desc, product_keywords
 *   cat_id   – filter by category ID
 *   brand_id – filter by brand ID
 *   limit    – maximum number of results (integer)
 *
 * When multiple filters are present the priority is:
 *   search > cat_id > brand_id > (all products)
 *
 * Each product row includes cat_name and brand_name from the joined tables.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../middleware/auth.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed. Use GET.', 405);
}

// Verify JWT — exits with 401 on failure
auth_middleware();

// -------------------------------------------------------------------------
// Read and sanitise query parameters
// -------------------------------------------------------------------------
$search   = isset($_GET['search'])   ? trim($_GET['search'])                             : null;
$cat_id   = isset($_GET['cat_id'])   && ctype_digit($_GET['cat_id'])   ? (int) $_GET['cat_id']   : null;
$brand_id = isset($_GET['brand_id']) && ctype_digit($_GET['brand_id']) ? (int) $_GET['brand_id'] : null;
$limit    = isset($_GET['limit'])    && ctype_digit($_GET['limit'])    ? (int) $_GET['limit']    : null;

if ($search === '') {
    $search = null;
}

// -------------------------------------------------------------------------
// Build and execute the query
// -------------------------------------------------------------------------
try {
    $pdo = Database::connect();

    $base_sql = '
        SELECT
            p.product_id,
            p.pharmacy_id,
            p.product_title,
            p.product_price,
            p.product_desc,
            p.product_image,
            p.product_keywords,
            p.product_stock,
            p.created_at,
            c.cat_id,
            c.cat_name,
            b.brand_id,
            b.brand_name
        FROM products p
        INNER JOIN categories c ON p.product_cat  = c.cat_id
        INNER JOIN brands     b ON p.product_brand = b.brand_id
    ';

    $params = [];

    if ($search !== null) {
        $sql    = $base_sql . ' WHERE p.product_title LIKE ? OR p.product_desc LIKE ? OR p.product_keywords LIKE ?';
        $term   = '%' . $search . '%';
        $params = [$term, $term, $term];
    } elseif ($cat_id !== null) {
        $sql    = $base_sql . ' WHERE p.product_cat = ?';
        $params = [$cat_id];
    } elseif ($brand_id !== null) {
        $sql    = $base_sql . ' WHERE p.product_brand = ?';
        $params = [$brand_id];
    } else {
        $sql = $base_sql;
    }

    $sql .= ' ORDER BY p.created_at DESC';

    if ($limit !== null) {
        $sql   .= ' LIMIT ' . $limit; // already cast to int — safe
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $products = $stmt->fetchAll();

} catch (PDOException $e) {
    error_log('Products index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success($products, count($products) . ' product(s) retrieved successfully.', 200);
