<?php
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

function respond($data) {
    echo json_encode($data);
    exit;
}

if ($method === 'GET') {
    $sql = "SELECT id, nama, usia_ibu, usia_kehamilan, updated_at FROM profil_ibu ORDER BY id ASC LIMIT 1";
    $result = $conn->query($sql);
    $data = $result && $result->num_rows > 0 ? $result->fetch_assoc() : new stdClass();
    respond($data);
}

if ($method === 'POST' || $method === 'PUT') {
    // Terima JSON atau form-encoded
    $input = json_decode(file_get_contents('php://input'), true);
    if (empty($input)) {
        $input = $_POST;
    }

    $nama = isset($input['nama']) ? trim($input['nama']) : '';
    $usiaIbu = isset($input['usia_ibu']) ? trim($input['usia_ibu']) : '';
    $usiaKehamilan = isset($input['usia_kehamilan']) ? trim($input['usia_kehamilan']) : null;

    if ($nama === '' || $usiaIbu === '') {
        respond(['status' => 'error', 'message' => 'nama dan usia_ibu wajib diisi']);
    }

    if (!is_numeric($usiaIbu) || intval($usiaIbu) <= 0 || intval($usiaIbu) > 60) {
        respond(['status' => 'error', 'message' => 'usia_ibu tidak valid']);
    }

    $stmt = $conn->prepare("INSERT INTO profil_ibu (id, nama, usia_ibu, usia_kehamilan, updated_at) VALUES (1, ?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE nama=VALUES(nama), usia_ibu=VALUES(usia_ibu), usia_kehamilan=VALUES(usia_kehamilan), updated_at=NOW()");
    $stmt->bind_param("sis", $nama, $usiaIbu, $usiaKehamilan);

    if ($stmt->execute()) {
        respond(['status' => 'success', 'message' => 'Profil tersimpan']);
    } else {
        respond(['status' => 'error', 'message' => 'Gagal menyimpan: ' . $stmt->error]);
    }
}

respond(['status' => 'error', 'message' => 'Method not allowed']);
?>
