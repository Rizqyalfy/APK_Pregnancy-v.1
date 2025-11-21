<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include '../config/db.php';

// Get POST data
$data = json_decode(file_get_contents("php://input"), true);

// Jika tidak pakai json, gunakan $_POST
$tekanan_darah = $_POST['tekanan_darah'] ?? '';
$berat_badan = $_POST['berat_badan'] ?? '';
$keluhan = $_POST['keluhan'] ?? '';
$pergerakan_janin = $_POST['pergerakan_janin'] ?? '';
$tanggal_pemeriksaan = $_POST['tanggal_pemeriksaan'] ?? '';
$jenis_kunjungan = $_POST['jenis_kunjungan'] ?? '';
$trimester = $_POST['trimester'] ?? '';
$hasil_lab = $_POST['hasil_lab'] ?? '';
$hasil_usg = $_POST['hasil_usg'] ?? '';
$imunisasi_tt = $_POST['imunisasi_tt'] ?? '';
$catatan_anc = $_POST['catatan_anc'] ?? '';

// Validasi data required
if (empty($tekanan_darah) || empty($berat_badan) || empty($tanggal_pemeriksaan)) {
    echo json_encode([
        "status" => "error",
        "message" => "Data required: tekanan_darah, berat_badan, tanggal_pemeriksaan"
    ]);
    exit;
}

// Insert ke database
$sql = "INSERT INTO data_ibu (
    tekanan_darah, berat_badan, keluhan, pergerakan_janin, 
    tanggal_pemeriksaan, jenis_kunjungan, trimester, 
    hasil_lab, hasil_usg, imunisasi_tt, catatan_anc
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);
$stmt->bind_param(
    "sssssssssss",
    $tekanan_darah, $berat_badan, $keluhan, $pergerakan_janin,
    $tanggal_pemeriksaan, $jenis_kunjungan, $trimester,
    $hasil_lab, $hasil_usg, $imunisasi_tt, $catatan_anc
);

if ($stmt->execute()) {
    echo json_encode([
        "status" => "success",
        "message" => "Data berhasil disimpan",
        "insert_id" => $stmt->insert_id
    ]);
} else {
    echo json_encode([
        "status" => "error", 
        "message" => "Gagal menyimpan data: " . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>