<?php
require '../config/db.php';

$sql = "SELECT id, berat_badan, tekanan_darah, created_at FROM data_ibu ORDER BY id ASC";
$result = $conn->query($sql);

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = [
        "id" => (int)$row["id"],
        "berat_badan" => (int)$row["berat_badan"],
        "tekanan_darah" => $row["tekanan_darah"],
        "tanggal" => $row["created_at"]
    ];
}

echo json_encode($data);
