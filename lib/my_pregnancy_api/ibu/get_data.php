<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include '../config/db.php';

$sql = "SELECT * FROM data_ibu ORDER BY tanggal_pemeriksaan DESC";
$result = $conn->query($sql);

$data = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    echo json_encode($data);
} else {
    echo json_encode([
        "status" => "success",
        "message" => "Tidak ada data",
        "data" => []
    ]);
}

$conn->close();
?>