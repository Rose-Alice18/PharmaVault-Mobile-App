<?php
/**
 * api/v1/cart/index.php
 *
 * GET /api/v1/cart
 *
 * Protected — returns all cart items for the logged-in customer,
 * with full product details, category name, brand name, and a
 * computed line_total (price × qty) for each row.
 *
 * Also returns a cart_total summary field at the top level so the
 * Flutter app does not have to sum client-side.
 *
 * Note on the schema: the cart table identifies items by p_id (product_id)
 * and c_id (customer_id). There is no separate cart_id column.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../middleware/auth.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed. Use GET.', 405);
}

$user        = auth_middleware();
$customer_id = (int) $user->customer_id;

try {
    $pdo  = Database::connect();
    $stmt = $pdo->prepare(
        'SELECT
            c.p_id        AS product_id,
            c.qty,
            p.product_title,
            p.product_price,
            p.product_image,
            p.product_stock,
            (p.product_price * c.qty) AS line_total,
            cat.cat_id,
            cat.cat_name,
            b.brand_id,
            b.brand_name
         FROM cart c
         INNER JOIN products   p   ON c.p_id          = p.product_id
         LEFT  JOIN categories cat ON p.product_cat   = cat.cat_id
         LEFT  JOIN brands     b   ON p.product_brand = b.brand_id
         WHERE c.c_id = ?'
    );
    $stmt->execute([$customer_id]);
    $items = $stmt->fetchAll();

    // Calculate cart total
    $cart_total = array_sum(array_column($items, 'line_total'));

} catch (PDOException $e) {
    error_log('Cart index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success(
    [
        'items'      => $items,
        'item_count' => count($items),
        'cart_total' => (float) $cart_total,
    ],
    'Cart retrieved successfully.',
    200
);
