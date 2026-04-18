<?php
/**
 * api/v1/prescriptions/upload.php
 *
 * POST /api/v1/prescriptions/upload   (multipart/form-data)
 *
 * Protected — saves a prescription image and creates a prescription record
 * linked to the logged-in customer.
 *
 * Required form field:
 *   prescription_image  — image file (JPEG / PNG / GIF / WebP, max 5 MB)
 *
 * Optional form fields:
 *   doctor_name            — string
 *   doctor_license         — string
 *   issue_date             — date (YYYY-MM-DD)
 *   expiry_date            — date (YYYY-MM-DD)
 *   prescription_notes     — text
 *   allow_pharmacy_access  — 1 or 0 (default 1)
 *
 * The prescription_number is generated automatically in the format
 * RX-YYYYMMDD-NNNNN, matching the Prescription class logic.
 *
 * Images are saved to uploads/prescriptions/{customer_id}/ inside the
 * project root so they can be served as static files.
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

// ── File validation ───────────────────────────────────────────────────────
if (!isset($_FILES['prescription_image']) || $_FILES['prescription_image']['error'] === UPLOAD_ERR_NO_FILE) {
    Response::error('prescription_image file is required.', 422);
}

$file  = $_FILES['prescription_image'];
$error = $file['error'];

if ($error !== UPLOAD_ERR_OK) {
    $upload_errors = [
        UPLOAD_ERR_INI_SIZE   => 'File exceeds server upload limit.',
        UPLOAD_ERR_FORM_SIZE  => 'File exceeds form size limit.',
        UPLOAD_ERR_PARTIAL    => 'File was only partially uploaded.',
        UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder.',
        UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk.',
        UPLOAD_ERR_EXTENSION  => 'Upload blocked by server extension.',
    ];
    Response::error($upload_errors[$error] ?? 'File upload failed.', 422);
}

// Max 5 MB
if ($file['size'] > 5 * 1024 * 1024) {
    Response::error('File size must not exceed 5 MB.', 422);
}

// Allowed MIME types
$allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
$finfo         = new finfo(FILEINFO_MIME_TYPE);
$mime          = $finfo->file($file['tmp_name']);

if (!in_array($mime, $allowed_types, true)) {
    Response::error('Only JPEG, PNG, GIF, and WebP images are accepted.', 422);
}

$ext_map = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/gif'  => 'gif',
    'image/webp' => 'webp',
];
$ext = $ext_map[$mime];

// ── Build destination path ────────────────────────────────────────────────
// Project root is two levels up from api/v1/prescriptions/
$project_root = dirname(__DIR__, 3);
$upload_dir   = $project_root . '/uploads/prescriptions/' . $customer_id . '/';

if (!is_dir($upload_dir) && !mkdir($upload_dir, 0755, true)) {
    error_log('Cannot create upload dir: ' . $upload_dir);
    Response::error('Could not create upload directory.', 500);
}

$filename      = 'rx_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
$dest_path     = $upload_dir . $filename;
$relative_path = 'uploads/prescriptions/' . $customer_id . '/' . $filename;

if (!move_uploaded_file($file['tmp_name'], $dest_path)) {
    Response::error('Failed to save the uploaded file.', 500);
}

// ── Generate prescription number (RX-YYYYMMDD-NNNNN) ─────────────────────
try {
    $pdo      = Database::connect();
    $cnt_stmt = $pdo->query(
        "SELECT COUNT(*) AS cnt FROM prescriptions WHERE DATE(uploaded_at) = CURDATE()"
    );
    $cnt_row  = $cnt_stmt->fetch();
    $sequence = str_pad((int) $cnt_row['cnt'] + 1, 5, '0', STR_PAD_LEFT);
    $rx_number = 'RX-' . date('Ymd') . '-' . $sequence;

    // ── Optional form fields ──────────────────────────────────────────────
    $doctor_name           = trim($_POST['doctor_name']        ?? '');
    $doctor_license        = trim($_POST['doctor_license']     ?? '');
    $issue_date            = !empty($_POST['issue_date'])    ? $_POST['issue_date']   : null;
    $expiry_date           = !empty($_POST['expiry_date'])   ? $_POST['expiry_date']  : null;
    $prescription_notes    = trim($_POST['prescription_notes'] ?? '');
    $allow_pharmacy_access = isset($_POST['allow_pharmacy_access'])
                             ? (int) (bool) $_POST['allow_pharmacy_access'] : 1;

    // Validate date formats if provided
    foreach (['issue_date' => $issue_date, 'expiry_date' => $expiry_date] as $field => $val) {
        if ($val !== null && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $val)) {
            Response::error("'{$field}' must be in YYYY-MM-DD format.", 422);
        }
    }

    // ── Insert prescription record ────────────────────────────────────────
    $ins = $pdo->prepare(
        'INSERT INTO prescriptions
            (customer_id, prescription_number, doctor_name, doctor_license,
             issue_date, expiry_date, prescription_image, prescription_notes,
             status, allow_pharmacy_access)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, \'pending\', ?)'
    );
    $ins->execute([
        $customer_id,
        $rx_number,
        $doctor_name ?: null,
        $doctor_license ?: null,
        $issue_date,
        $expiry_date,
        $relative_path,
        $prescription_notes ?: null,
        $allow_pharmacy_access,
    ]);

    $prescription_id = (int) $pdo->lastInsertId();

} catch (PDOException $e) {
    // Clean up the uploaded file if the DB insert fails
    @unlink($dest_path);
    error_log('Prescription upload error: ' . $e->getMessage());
    Response::error('A server error occurred while saving your prescription.', 500);
}

Response::success(
    [
        'prescription_id'     => $prescription_id,
        'prescription_number' => $rx_number,
        'prescription_image'  => $relative_path,
        'status'              => 'pending',
    ],
    'Prescription uploaded successfully.',
    201
);
