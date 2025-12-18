<?php
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
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
    $sql = "SELECT id, judul, tanggal, catatan, created_at FROM jurnal_ibu ORDER BY tanggal DESC, id DESC";
    $result = $conn->query($sql);
    $data = [];
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
    }
    respond($data);
}

if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (empty($input)) {
        $input = $_POST;
    }

    $judul = isset($input['judul']) ? trim($input['judul']) : '';
    $tanggal = isset($input['tanggal']) ? trim($input['tanggal']) : '';
    $catatan = isset($input['catatan']) ? trim($input['catatan']) : '';

    if ($judul === '' || $tanggal === '') {
        respond(['status' => 'error', 'message' => 'judul dan tanggal wajib diisi']);
    }

    $stmt = $conn->prepare("INSERT INTO jurnal_ibu (judul, tanggal, catatan) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $judul, $tanggal, $catatan);

    if ($stmt->execute()) {
        respond(['status' => 'success', 'message' => 'Jurnal ditambahkan', 'id' => $stmt->insert_id]);
    } else {
        respond(['status' => 'error', 'message' => 'Gagal menambah jurnal: ' . $stmt->error]);
    }
}

if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? intval($_GET['id']) : 0;
    if ($id <= 0) {
        respond(['status' => 'error', 'message' => 'ID tidak valid']);
    }

    $stmt = $conn->prepare("DELETE FROM jurnal_ibu WHERE id = ?");
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        respond(['status' => 'success', 'message' => 'Jurnal dihapus']);
    } else {
        respond(['status' => 'error', 'message' => 'Gagal menghapus: ' . $stmt->error]);
    }
}

respond(['status' => 'error', 'message' => 'Method not allowed']);
?>
