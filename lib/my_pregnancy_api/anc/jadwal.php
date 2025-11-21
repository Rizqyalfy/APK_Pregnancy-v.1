<?php
require '../config/db.php';

$sql = "SELECT * FROM jadwal_anc ORDER BY tanggal ASC";
$result = $conn->query($sql);

$jadwal = [];

while ($row = $result->fetch_assoc()) {
    $jadwal[] = $row;
}

echo json_encode($jadwal);
