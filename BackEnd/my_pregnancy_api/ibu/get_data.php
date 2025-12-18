<?php
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 0;
$sql = "SELECT * FROM data_ibu ORDER BY tanggal_pemeriksaan DESC";
if ($limit > 0) {
    $sql .= " LIMIT $limit";
}

$result = $conn->query($sql);
$data = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Format tanggal jadi DD/MM/YYYY seperti di frontend
        $row['tanggal'] = date('d/m/Y', strtotime($row['tanggal_pemeriksaan']));
        
        // Map snake_case ke camelCase untuk frontend
        $row['tekananDarah'] = $row['tekanan_darah'] ?? '';
        $row['beratBadan'] = $row['berat_badan'] ?? '';
        $row['tinggiFundus'] = $row['tinggi_fundus'] ?? '';
        $row['kadarHb'] = $row['kadar_hb'] ?? '';
        $row['usiaKehamilan'] = ''; // akan diisi dari tabel lain jika ada
        $row['perkembanganJanin'] = $row['pergerakan_janin'] ?? '';
        
        // Gabungkan semua ke 'hasil' seperti di frontend
        $row['hasil'] = implode(' • ', array_filter([
            $row['tekanan_darah'] ? "TD: {$row['tekanan_darah']}" : null,
            $row['berat_badan'] ? "BB: {$row['berat_badan']}" : null,
            $row['keluhan'] ? "Keluhan: {$row['keluhan']}" : null,
            $row['pergerakan_janin'] ? "Pergerakan: {$row['pergerakan_janin']}" : null,
            $row['hasil_lab'] ? "Lab: {$row['hasil_lab']}" : null,
            $row['hasil_usg'] ? "USG: {$row['hasil_usg']}" : null,
            "Imunisasi TT: {$row['imunisasi_tt']}",
            "Trimester: {$row['trimester']}",
            "Jenis: {$row['jenis_kunjungan']}"
        ]));
        
        // Pastikan gambar field selalu ada (untuk compatibility dengan Flutter)
        if (!isset($row['gambar']) || $row['gambar'] === null) {
            $row['gambar'] = '';
        }
        
        $data[] = $row;
    }
}

echo json_encode($data);
$conn->close();
?>