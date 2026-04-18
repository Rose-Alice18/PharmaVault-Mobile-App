<?php
/**
 * api/utils/response.php
 *
 * Centralised JSON response helper.
 * All responses share the same envelope:
 *
 *   { "status": "success"|"error", "message": "...", "data": ... }
 *
 * Both methods call exit() so callers do not need an explicit return
 * statement after an error response.
 */

class Response
{
    /**
     * Send a successful JSON response.
     *
     * @param mixed  $data    Payload (array, object, or null).
     * @param string $message Human-readable status message.
     * @param int    $code    HTTP status code (default 200).
     */
    public static function success($data = null, string $message = 'Success', int $code = 200): void
    {
        http_response_code($code);
        echo json_encode([
            'status'  => 'success',
            'message' => $message,
            'data'    => $data,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit();
    }

    /**
     * Send an error JSON response.
     *
     * @param string $message Human-readable error description.
     * @param int    $code    HTTP status code (default 400).
     */
    public static function error(string $message = 'An error occurred', int $code = 400): void
    {
        http_response_code($code);
        echo json_encode([
            'status'  => 'error',
            'message' => $message,
            'data'    => null,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit();
    }
}
