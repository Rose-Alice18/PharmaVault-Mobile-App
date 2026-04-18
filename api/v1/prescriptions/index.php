<?php
/**
 * api/v1/prescriptions/index.php
 *
 * GET /api/v1/prescriptions
 *
 * Protected — returns all prescriptions uploaded by the logged-in customer,
 * ordered most-recent first.
 *
 * Optional query parameter:
 *   status — filter by status: pending | verified | rejected | expired
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

// Optional status filter — only accept known enum values
$allowed_statuses = ['pending', 'verified', 'rejected', 'expired'];
$status = isset($_GET['status']) && in_array($_GET['status'], $allowed_statuses, true)
          ? $_GET['status'] : null;

try {
    $pdo = Database::connect();

    if ($status !== null) {
        $stmt = $pdo->prepare(
            'SELECT
                prescription_id,
                prescription_number,
                doctor_name,
                issue_date,
                expiry_date,
                prescription_image,
                prescription_notes,
                status,
                allow_pharmacy_access,
                uploaded_at,
                updated_at
             FROM prescriptions
             WHERE customer_id = ? AND status = ?
             ORDER BY uploaded_at DESC'
        );
        $stmt->execute([$customer_id, $status]);
    } else {
        $stmt = $pdo->prepare(
            'SELECT
                prescription_id,
                prescription_number,
                doctor_name,
                issue_date,
                expiry_date,
                prescription_image,
                prescription_notes,
                status,
                allow_pharmacy_access,
                uploaded_at,
                updated_at
             FROM prescriptions
             WHERE customer_id = ?
             ORDER BY uploaded_at DESC'
        );
        $stmt->execute([$customer_id]);
    }

    $prescriptions = $stmt->fetchAll();

    // Cast boolean field
    foreach ($prescriptions as &$rx) {
        $rx['allow_pharmacy_access'] = (bool) $rx['allow_pharmacy_access'];
    }
    unset($rx);

} catch (PDOException $e) {
    error_log('Prescriptions index error: ' . $e->getMessage());
    Response::error('A server error occurred. Please try again later.', 500);
}

Response::success($prescriptions, count($prescriptions) . ' prescription(s) retrieved.', 200);
