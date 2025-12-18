<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json; charset=UTF-8");

echo json_encode([
  "reminder" => "Jangan lupa minum vitamin folat hari ini!",
  "status" => "normal",
  "pesan" => "Tidak ada tanda bahaya."
]);
