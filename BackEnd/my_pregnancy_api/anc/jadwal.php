<?php
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$method = $_SERVER['REQUEST_METHOD'];

// --------------------------
// GET: Ambil semua jadwal
// --------------------------
if ($method === 'GET') {
    $sql = "SELECT id, minggu, judul, tanggal, jam, catatan FROM jadwal_anc ORDER BY tanggal ASC";
    $result = $conn->query($sql);
    $data = [];
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
    }
    echo json_encode($data);
    $conn->close();
    exit;
}

// --------------------------
// POST: Tambah jadwal baru
// --------------------------
if ($method === 'POST') {
    $required = ['minggu', 'judul', 'tanggal'];
    foreach ($required as $field) {
        if (!isset($_POST[$field]) || trim($_POST[$field]) === '') {
            echo json_encode(['status' => 'error', 'message' => "$field wajib diisi"]);
            exit;
        }
    }

    $stmt = $conn->prepare("INSERT INTO jadwal_anc (minggu, judul, tanggal, jam, catatan) VALUES (?, ?, ?, ?, ?)");
    $minggu = $_POST['minggu'];
    $judul = $_POST['judul'];
    $tanggal = $_POST['tanggal'];
    $jam = $_POST['jam'] ?? '09:00';
    $catatan = $_POST['catatan'] ?? '';

    $stmt->bind_param("sssss", $minggu, $judul, $tanggal, $jam, $catatan);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Jadwal berhasil ditambahkan']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Gagal: ' . $stmt->error]);
    }
    $stmt->close();
    $conn->close();
    exit;
}

// --------------------------
// PUT: Update jadwal (pakai ?id=)
// --------------------------
if ($method === 'PUT') {
    parse_str(file_get_contents("php://input"), $put_vars);
    $id = $_GET['id'] ?? null;

    if (!$id || !is_numeric($id)) {
        echo json_encode(['status' => 'error', 'message' => 'ID tidak valid']);
        exit;
    }

    $required = ['minggu', 'judul', 'tanggal'];
    foreach ($required as $field) {
        if (!isset($put_vars[$field]) || trim($put_vars[$field]) === '') {
            echo json_encode(['status' => 'error', 'message' => "$field wajib diisi"]);
            exit;
        }
    }

    $stmt = $conn->prepare("UPDATE jadwal_anc SET minggu=?, judul=?, tanggal=?, jam=?, catatan=? WHERE id=?");
    $minggu = $put_vars['minggu'];
    $judul = $put_vars['judul'];
    $tanggal = $put_vars['tanggal'];
    $jam = $put_vars['jam'] ?? '09:00';
    $catatan = $put_vars['catatan'] ?? '';
    
    $stmt->bind_param("sssssi", $minggu, $judul, $tanggal, $jam, $catatan, $id);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Jadwal berhasil diupdate']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Gagal update: ' . $stmt->error]);
    }
    $stmt->close();
    $conn->close();
    exit;
}

// --------------------------
// DELETE: Hapus jadwal
// --------------------------
if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id || !is_numeric($id)) {
        echo json_encode(['status' => 'error', 'message' => 'ID tidak valid']);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM jadwal_anc WHERE id = ?");
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Jadwal berhasil dihapus']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Gagal hapus: ' . $stmt->error]);
    }
    $stmt->close();
    $conn->close();
    exit;
}

// Jika method tidak didukung
echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
$conn->close();
?>