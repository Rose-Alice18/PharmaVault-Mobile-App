<?php
/**
 * api/v1/orders/show.php
 *
 * GET /api/v1/orders/show?order_id={id}
 *
 * Protected — returns the full detail of one order belonging to the
 * logged-in customer: order header, all line items with product info,
 * payment record, and delivery details.
 *
 * Responds 403 if the order_id exists but belongs to a different customer.
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

if (!isset($_GET['order_id']) || !ctype_digit($_GET['order_id']) || (int) $_GET['order_id'] <= 0) {
    Response::error('A valid numeric order_id query parameter is required.', 422);
}

$order_id = (int) $_GET['order_id'];

try {
    $pdo = Database::connect();

    // ── Order header ──────────────────────────────────────────────────────
    $header_stmt = $pdo->prepare(
        'SELECT
            o.order_id,
            o.customer_id,
            o.invoice_no,
            o.order_date,
            o.order_status,
            o.delivery_method,
            o.delivery_notes,
            COALESCE(p.pay_id, 0)         AS pay_id,
            COALESCE(p.amt, 0)            AS payment_amount,
            COALESCE(p.currency, \'GHS\') AS currency,
            p.payment_date,
            CASE WHEN p.pay_id IS NOT NULL THEN 1 ELSE 0 END AS is_paid
         FROM orders o
         LEFT JOIN payment p ON o.order_id = p.order_id
         WHERE o.order_id = ?
         LIMIT 1'
    );
    $header_stmt->execute([$order_id]);
    $order = $header_stmt->fetch();

    if (!$order) {
        Response::error('Order not found.', 404);
    }

    // Ownership check — customers can only view their own orders
    if ((int) $order['customer_id'] !== $customer_id) {
        Response::error('You do not have permission to view this order.', 403);
    }

    // ── Order line items ──────────────────────────────────────────────────
    $items_stmt = $pdo->prepare(
        'SELECT
            od.product_id,
            od.qty,
            p.product_title,
            p.product_price,
            p.product_image,
            (p.product_price * od.qty) AS line_total,
            c.cat_name,
            b.brand_name
         FROM orderdetails od
         INNER JOIN products   p ON od.product_id    = p.product_id
         LEFT  JOIN categories c ON p.product_cat    = c.cat_id
         LEFT  JOIN brands     b ON p.product_brand  = b.brand_id
         WHERE od.order_id = ?'
    );
    $items_stmt->execute([$order_id]);
    $items = $items_stmt->fetchAll();

    // Compute order total from items
    $order_total = array_sum(array_column($items, 'line_total'));

    // Cast types
    $order['order_id']       = (int)   $order['order_id'];
    $order['invoice_no']     = (int)   $order['invoice_no'];
    $order['payment_amount'] = (float) $order['payment_amount'];
    $order['is_paid']        = (bool)  $order['is_paid'];
    unset($order['customer_id']); // don't expose in response

    foreach ($items as &$item) {
        $item['product_id'] = (int)   $item['product_id'];
        $item['qty']        = (int)   $item['qty'];
        $item['line_total'] = (float) $item['line_total'];
    }
    unset($item);

} catch (PDOException $e) {
    error_log('Order show error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success(
    [
        'order'       => $order,
        'items'       => $items,
        'order_total' => (float) $order_total,
        'item_count'  => count($items),
    ],
    'Order retrieved successfully.',
    200
);
