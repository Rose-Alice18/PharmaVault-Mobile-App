<?php
/**
 * api/v1/products/show.php
 *
 * GET /api/v1/products/show?id={product_id}
 *
 * Protected — requires a valid JWT Bearer token.
 *
 * Returns the full product record for the given ID, including
 * category name and brand name from the joined tables.
 * Responds with 404 if the product does not exist.
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
// Validate the id query parameter
// -------------------------------------------------------------------------
if (!isset($_GET['id']) || !ctype_digit($_GET['id']) || (int) $_GET['id'] <= 0) {
    Response::error('A valid numeric id query parameter is required.', 422);
}

$product_id = (int) $_GET['id'];

// -------------------------------------------------------------------------
// Fetch the product
// -------------------------------------------------------------------------
try {
    $pdo  = Database::connect();
    $stmt = $pdo->prepare('
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
        WHERE p.product_id = ?
        LIMIT 1
    ');
    $stmt->execute([$product_id]);
    $product = $stmt->fetch();

} catch (PDOException $e) {
    error_log('Product show error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

if (!$product) {
    Response::error('Product not found.', 404);
}

Response::success($product, 'Product retrieved successfully.', 200);
