<?php
/**
 * api/v1/cart/add.php
 *
 * POST /api/v1/cart/add
 *
 * Protected — adds a product to the logged-in customer's cart.
 * If the product is already in the cart the qty is incremented
 * (not replaced) up to the available stock cap.
 *
 * Request body (JSON):
 *   { "product_id": 5, "qty": 2 }
 *
 * qty defaults to 1 if omitted.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../middleware/auth.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed. Use POST.', 405);
}

$user        = auth_middleware();
$customer_id = (int) $user->customer_id;

$body       = json_decode(file_get_contents('php://input'), true);
$product_id = isset($body['product_id']) && ctype_digit((string) $body['product_id'])
              ? (int) $body['product_id'] : 0;
$qty        = isset($body['qty']) && ctype_digit((string) $body['qty']) && (int) $body['qty'] > 0
              ? (int) $body['qty'] : 1;

if ($product_id <= 0) {
    Response::error('A valid product_id is required.', 422);
}

try {
    $pdo = Database::connect();

    // Verify product exists and check available stock
    $prod_stmt = $pdo->prepare(
        'SELECT product_id, product_title, product_stock FROM products WHERE product_id = ? LIMIT 1'
    );
    $prod_stmt->execute([$product_id]);
    $product = $prod_stmt->fetch();

    if (!$product) {
        Response::error('Product not found.', 404);
    }

    $available_stock = (int) $product['product_stock'];

    if ($available_stock <= 0) {
        Response::error('This product is currently out of stock.', 409);
    }

    // Check if product is already in customer's cart
    $check_stmt = $pdo->prepare(
        'SELECT qty FROM cart WHERE p_id = ? AND c_id = ? LIMIT 1'
    );
    $check_stmt->execute([$product_id, $customer_id]);
    $existing = $check_stmt->fetch();

    if ($existing) {
        // Increment quantity, capped at available stock
        $new_qty = min((int) $existing['qty'] + $qty, $available_stock);
        $upd     = $pdo->prepare('UPDATE cart SET qty = ? WHERE p_id = ? AND c_id = ?');
        $upd->execute([$new_qty, $product_id, $customer_id]);
        $message = 'Cart quantity updated.';
    } else {
        // Insert new row — cap qty at available stock
        $qty = min($qty, $available_stock);
        $ins = $pdo->prepare(
            'INSERT INTO cart (p_id, c_id, ip_add, qty) VALUES (?, ?, ?, ?)'
        );
        $ip_add = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        $ins->execute([$product_id, $customer_id, $ip_add, $qty]);
        $message = 'Product added to cart.';
    }

} catch (PDOException $e) {
    error_log('Cart add error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success(
    ['product_id' => $product_id, 'qty' => $new_qty ?? $qty],
    $message,
    200
);
