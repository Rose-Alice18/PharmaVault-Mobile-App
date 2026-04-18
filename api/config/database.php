<?php
/**
 * api/config/database.php
 *
 * Standalone database configuration for the PharmaVault mobile API.
 * Provides a PDO singleton that every endpoint can call via Database::connect().
 *
 * Credentials match the existing pharmavault_db MySQL database.
 * Change them here if the server environment differs from development.
 */

define('DB_HOST',     'localhost');
define('DB_NAME',     'pharmavault_db');
define('DB_USER',     'root');
define('DB_PASS',     '');
define('DB_CHARSET',  'utf8mb4');

// -------------------------------------------------------------------------
// JWT configuration
// -------------------------------------------------------------------------
// Replace JWT_SECRET with a long random string before going to production.
define('JWT_SECRET', 'pharmavault_jwt_secret_change_me_in_production_2025');
define('JWT_EXPIRY',  60 * 60 * 24 * 7); // 7 days in seconds

class Database
{
    private static ?PDO $instance = null;

    /**
     * Return the shared PDO connection (creates it on first call).
     */
    public static function connect(): PDO
    {
        if (self::$instance === null) {
            $dsn = sprintf(
                'mysql:host=%s;dbname=%s;charset=%s',
                DB_HOST, DB_NAME, DB_CHARSET
            );

            self::$instance = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        }

        return self::$instance;
    }
}
