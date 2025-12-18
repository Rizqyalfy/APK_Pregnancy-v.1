<?php
// config/database.php
error_reporting(0);
ini_set('display_errors', 0);

$host = "localhost";
$username = "root";       // ganti sesuai server Anda
$password = "";           // ganti jika ada password
$database = "my_pregnancy";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    header('Content-Type: application/json');
    die(json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . $conn->connect_error]));
}
?>