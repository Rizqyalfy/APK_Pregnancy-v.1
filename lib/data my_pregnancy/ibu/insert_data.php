<?php
require '../config/db.php';

$td = $_POST["tekanan_darah"] ?? "";
$bb = $_POST["berat_badan"] ?? "";
$keluhan = $_POST["keluhan"] ?? "";
$pj = $_POST["pergerakan_janin"] ?? "";

$sql = "INSERT INTO data_ibu (tekanan_darah, berat_badan, keluhan, pergerakan_janin)
        VALUES ('$td', '$bb', '$keluhan', '$pj')";

if ($conn->query($sql)) {
    echo json_encode(["status" => "success","message" => "Data berhasil disimpan"]);
} else {
    echo json_encode(["status" => "error","message" => $conn->error]);
}
