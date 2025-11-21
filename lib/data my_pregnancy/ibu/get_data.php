<?php
require '../config/db.php';

$sql = "SELECT * FROM data_ibu ORDER BY created_at DESC LIMIT 1";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode(["status"=>"success","data"=>$result->fetch_assoc()]);
} else {
    echo json_encode(["status"=>"empty"]);
}
