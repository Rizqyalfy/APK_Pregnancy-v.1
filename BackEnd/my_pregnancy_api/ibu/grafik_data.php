<?php
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$sql = "SELECT 
    berat_badan, 
    tinggi_fundus, 
    tekanan_darah,
    tanggal_pemeriksaan 
FROM data_ibu 
WHERE berat_badan REGEXP '^[0-9.]+$' 
ORDER BY tanggal_pemeriksaan ASC";

$result = $conn->query($sql);
$data = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Ambil angka dari string (misal "58 kg" → 58)
        $berat = (float) filter_var($row['berat_badan'], FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
        $fundus = (float) filter_var($row['tinggi_fundus'], FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
        
        // Ambil sistolik dari "110/80" → 110
        $td = explode('/', $row['tekanan_darah']);
        $sistolik = (float)($td[0] ?? 0);

        $data[] = [
            'tanggal' => $row['tanggal_pemeriksaan'],
            'berat_badan' => $berat,
            'tinggi_fundus' => $fundus,
            'tekanan_darah' => $sistolik
        ];
    }
}

echo json_encode($data);
$conn->close();
?>