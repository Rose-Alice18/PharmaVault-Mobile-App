<?php
/**
 * api/v1/orders/create.php
 *
 * POST /api/v1/orders/create
 *
 * Protected — converts the logged-in customer's active cart into a new order.
 *
 * Request body (JSON):
 *   {
 *     "delivery_address": "25 Main Street",
 *     "delivery_city":    "Accra",
 *     "delivery_contact": "+233200000000"
 *   }
 *
 * Steps:
 *   1. Validate cart is not empty
 *   2. Validate all cart items still have sufficient stock
 *   3. Generate a unique invoice number
 *   4. INSERT into orders (delivery info stored in delivery_notes as JSON)
 *   5. INSERT one row in orderdetails per cart item
 *   6. Clear the customer's cart
 *   7. Return the new order_id and invoice_no
 *
 * Note: payment recording is handled separately (via a payment gateway
 * callback) — this endpoint only creates the order record.
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

// ── Validate request body ─────────────────────────────────────────────────
$body = json_decode(file_get_contents('php://input'), true);

foreach (['delivery_address', 'delivery_city', 'delivery_contact'] as $field) {
    if (empty(trim($body[$field] ?? ''))) {
        Response::error("Field '{$field}' is required.", 422);
    }
}

$delivery_address = trim($body['delivery_address']);
$delivery_city    = trim($body['delivery_city']);
$delivery_contact = trim($body['delivery_contact']);

try {
    $pdo = Database::connect();

    // ── Load cart items ───────────────────────────────────────────────────
    $cart_stmt = $pdo->prepare(
        'SELECT c.p_id AS product_id, c.qty, p.product_price, p.product_stock, p.product_title
         FROM cart c
         INNER JOIN products p ON c.p_id = p.product_id
         WHERE c.c_id = ?'
    );
    $cart_stmt->execute([$customer_id]);
    $cart_items = $cart_stmt->fetchAll();

    if (empty($cart_items)) {
        Response::error('Your cart is empty. Add items before placing an order.', 422);
    }

    // ── Stock validation ──────────────────────────────────────────────────
    foreach ($cart_items as $item) {
        if ($item['qty'] > (int) $item['product_stock']) {
            Response::error(
                "Insufficient stock for '{$item['product_title']}'. "
                . "Available: {$item['product_stock']}, requested: {$item['qty']}.",
                409
            );
        }
    }

    // ── Generate invoice number (matches Order::generate_invoice_number logic) ──
    $inv_stmt = $pdo->query(
        'SELECT MAX(invoice_no) AS max_inv FROM orders WHERE DATE(order_date) = CURDATE()'
    );
    $inv_row     = $inv_stmt->fetch();
    $invoice_no  = $inv_row['max_inv']
                   ? ((int) $inv_row['max_inv'] + 1)
                   : (int) (date('Ymd') . '00001');

    // ── Encode delivery details into delivery_notes ───────────────────────
    $delivery_notes = json_encode([
        'address' => $delivery_address,
        'city'    => $delivery_city,
        'contact' => $delivery_contact,
    ]);

    // ── Insert order (transaction) ────────────────────────────────────────
    $pdo->beginTransaction();

    $order_stmt = $pdo->prepare(
        'INSERT INTO orders (customer_id, invoice_no, order_date, order_status,
                             delivery_method, delivery_notes)
         VALUES (?, ?, CURDATE(), \'pending\', \'platform_rider\', ?)'
    );
    $order_stmt->execute([$customer_id, $invoice_no, $delivery_notes]);
    $order_id = (int) $pdo->lastInsertId();

    // ── Insert order details ──────────────────────────────────────────────
    $detail_stmt = $pdo->prepare(
        'INSERT INTO orderdetails (order_id, product_id, qty) VALUES (?, ?, ?)'
    );
    foreach ($cart_items as $item) {
        $detail_stmt->execute([$order_id, $item['product_id'], $item['qty']]);
    }

    // ── Clear cart ────────────────────────────────────────────────────────
    $clear_stmt = $pdo->prepare('DELETE FROM cart WHERE c_id = ?');
    $clear_stmt->execute([$customer_id]);

    $pdo->commit();

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Order create error: ' . $e->getMessage());
    Response::error('A server error occurred while placing your order.', 500);
}

Response::success(
    [
        'order_id'   => $order_id,
        'invoice_no' => $invoice_no,
        'item_count' => count($cart_items),
        'status'     => 'pending',
    ],
    'Order placed successfully.',
    201
);
