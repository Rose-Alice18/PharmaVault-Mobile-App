<?php
/**
 * api/middleware/auth.php
 *
 * JWT Bearer-token middleware for protected endpoints.
 *
 * Usage in any endpoint:
 *
 *   require_once __DIR__ . '/../../../middleware/auth.php';
 *   $user = auth_middleware();
 *   // $user->customer_id, $user->user_role, $user->customer_name are now available
 *
 * Terminates with 401 if the token is missing, expired, or invalid.
 * On success returns the decoded JWT payload as a stdClass object.
 */

require_once __DIR__ . '/../config/database.php';  // JWT_SECRET constant
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../../vendor/autoload.php'; // firebase/php-jwt via composer

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use Firebase\JWT\BeforeValidException;

/**
 * Validate the Bearer token in the Authorization header.
 *
 * @return object Decoded JWT payload (stdClass).
 */
function auth_middleware(): object
{
    $auth_header = '';

    // getallheaders() works on Apache; $_SERVER fallback covers nginx / FastCGI.
    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $name => $value) {
            if (strtolower($name) === 'authorization') {
                $auth_header = $value;
                break;
            }
        }
    }

    if ($auth_header === '' && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth_header = $_SERVER['HTTP_AUTHORIZATION'];
    }

    if ($auth_header === '' || substr($auth_header, 0, 7) !== 'Bearer ') {
        Response::error('Unauthorized: Missing or malformed Authorization header.', 401);
        exit();
    }

    $token = substr($auth_header, 7); // strip the "Bearer " prefix

    try {
        return JWT::decode($token, new Key(JWT_SECRET, 'HS256'));
    } catch (ExpiredException $e) {
        Response::error('Unauthorized: Token has expired. Please log in again.', 401);
        exit();
    } catch (SignatureInvalidException $e) {
        Response::error('Unauthorized: Invalid token signature.', 401);
        exit();
    } catch (BeforeValidException $e) {
        Response::error('Unauthorized: Token is not yet valid.', 401);
        exit();
    } catch (Exception $e) {
        Response::error('Unauthorized: ' . $e->getMessage(), 401);
        exit();
    }
}
