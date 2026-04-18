<?php
/**
 * api/v1/orders/index.php
 *
 * GET /api/v1/orders
 *
 * Protected — returns all orders for the logged-in customer.
 * Each order row includes: order header fields, payment amount,
 * payment status (paid / unpaid), and a computed order_total
 * calculated from the orderdetails items.
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
            o.order_id,
            o.invoice_no,
            o.order_date,
            o.order_status,
            o.delivery_method,
            o.delivery_notes,
            COALESCE(p.amt, 0)        AS payment_amount,
            COALESCE(p.currency, \'GHS\') AS currency,
            p.payment_date,
            CASE WHEN p.pay_id IS NOT NULL THEN 1 ELSE 0 END AS is_paid,
            COALESCE(
                (SELECT SUM(pr.product_price * od.qty)
                 FROM orderdetails od
                 INNER JOIN products pr ON od.product_id = pr.product_id
                 WHERE od.order_id = o.order_id),
                0
            ) AS order_total
         FROM orders o
         LEFT JOIN payment p ON o.order_id = p.order_id
         WHERE o.customer_id = ?
         ORDER BY o.order_date DESC'
    );
    $stmt->execute([$customer_id]);
    $orders = $stmt->fetchAll();

    // Cast numeric fields
    foreach ($orders as &$order) {
        $order['order_id']       = (int)   $order['order_id'];
        $order['invoice_no']     = (int)   $order['invoice_no'];
        $order['payment_amount'] = (float) $order['payment_amount'];
        $order['order_total']    = (float) $order['order_total'];
        $order['is_paid']        = (bool)  $order['is_paid'];
    }
    unset($order);

} catch (PDOException $e) {
    error_log('Orders index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success($orders, count($orders) . ' order(s) retrieved.', 200);
