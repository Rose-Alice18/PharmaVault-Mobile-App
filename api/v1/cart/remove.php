<?php
/**
 * api/v1/cart/remove.php
 *
 * DELETE /api/v1/cart/remove
 *
 * Protected — removes a single item from the logged-in customer's cart.
 *
 * Request body (JSON):
 *   { "product_id": 5 }
 *
 * Note: the cart table identifies items by product_id (p_id) + customer_id,
 * so product_id acts as the cart item identifier (there is no cart_id column).
 */

require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../middleware/auth.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    Response::error('Method not allowed. Use DELETE.', 405);
}

$user        = auth_middleware();
$customer_id = (int) $user->customer_id;

$body       = json_decode(file_get_contents('php://input'), true);
$product_id = isset($body['product_id']) && ctype_digit((string) $body['product_id'])
              ? (int) $body['product_id'] : 0;

if ($product_id <= 0) {
    Response::error('A valid product_id is required.', 422);
}

try {
    $pdo = Database::connect();

    // Confirm the item belongs to this customer before deleting
    $check = $pdo->prepare('SELECT qty FROM cart WHERE p_id = ? AND c_id = ? LIMIT 1');
    $check->execute([$product_id, $customer_id]);
    if (!$check->fetch()) {
        Response::error('Item not found in your cart.', 404);
    }

    $del = $pdo->prepare('DELETE FROM cart WHERE p_id = ? AND c_id = ?');
    $del->execute([$product_id, $customer_id]);

} catch (PDOException $e) {
    error_log('Cart remove error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success(null, 'Item removed from cart.', 200);
