<?php
/**
 * api/v1/cart/update.php
 *
 * PUT /api/v1/cart/update
 *
 * Protected — updates the quantity of a cart item for the logged-in customer.
 * If qty is set to 0 the item is removed automatically.
 *
 * Request body (JSON):
 *   { "product_id": 5, "qty": 3 }
 *
 * Note on naming: the cart table has no cart_id column. Items are uniquely
 * identified by (product_id + customer_id), so product_id acts as the
 * cart item identifier here.
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../middleware/auth.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    Response::error('Method not allowed. Use PUT.', 405);
}

$user        = auth_middleware();
$customer_id = (int) $user->customer_id;

$body       = json_decode(file_get_contents('php://input'), true);
$product_id = isset($body['product_id']) && ctype_digit((string) $body['product_id'])
              ? (int) $body['product_id'] : 0;
$qty        = isset($body['qty']) && is_numeric($body['qty'])
              ? (int) $body['qty'] : -1;

if ($product_id <= 0) {
    Response::error('A valid product_id is required.', 422);
}
if ($qty < 0) {
    Response::error('qty must be 0 or a positive integer.', 422);
}

try {
    $pdo = Database::connect();

    // Verify the item is actually in this customer's cart
    $check = $pdo->prepare('SELECT qty FROM cart WHERE p_id = ? AND c_id = ? LIMIT 1');
    $check->execute([$product_id, $customer_id]);
    if (!$check->fetch()) {
        Response::error('Item not found in cart.', 404);
    }

    if ($qty === 0) {
        // Remove item instead of setting qty to zero
        $del = $pdo->prepare('DELETE FROM cart WHERE p_id = ? AND c_id = ?');
        $del->execute([$product_id, $customer_id]);
        Response::success(null, 'Item removed from cart.', 200);
    }

    // Cap quantity at available stock
    $prod_stmt = $pdo->prepare('SELECT product_stock FROM products WHERE product_id = ? LIMIT 1');
    $prod_stmt->execute([$product_id]);
    $product = $prod_stmt->fetch();

    if (!$product) {
        Response::error('Product not found.', 404);
    }

    $qty = min($qty, (int) $product['product_stock']);

    $upd = $pdo->prepare('UPDATE cart SET qty = ? WHERE p_id = ? AND c_id = ?');
    $upd->execute([$qty, $product_id, $customer_id]);

} catch (PDOException $e) {
    error_log('Cart update error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success(
    ['product_id' => $product_id, 'qty' => $qty],
    'Cart updated successfully.',
    200
);
