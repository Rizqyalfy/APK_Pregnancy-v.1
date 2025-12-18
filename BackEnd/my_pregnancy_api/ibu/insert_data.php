<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/../../uploads/php_errors.log');

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';

$upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/my_pregnancy_api/uploads/';

// Debug log
if (!is_dir($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}
file_put_contents($upload_dir . 'debug.log', 
    date('Y-m-d H:i:s') . " - REQUEST METHOD: " . $_SERVER['REQUEST_METHOD'] . "\n" .
    "FILES: " . print_r($_FILES, true) . "\n" .
    "POST: " . print_r($_POST, true) . "\n\n",
    FILE_APPEND
);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Only POST method allowed']);
    exit;
}

// Handle foto_usg upload jika ada file
$foto_usg_filename = null;
if (isset($_FILES['foto_usg']) && $_FILES['foto_usg']['error'] === UPLOAD_ERR_OK) {
    // Path absolut ke folder uploads
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/my_pregnancy_api/uploads/';
    
    // Buat folder uploads jika belum ada
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    
    // Debug path
    file_put_contents($upload_dir . 'debug.log', 
        date('Y-m-d H:i:s') . " - Upload dir: " . $upload_dir . "\n" .
        "Document root: " . $_SERVER['DOCUMENT_ROOT'] . "\n" .
        "File name: " . $_FILES['foto_usg']['name'] . "\n" .
        "File size: " . $_FILES['foto_usg']['size'] . "\n" .
        "Temp file: " . $_FILES['foto_usg']['tmp_name'] . "\n\n",
        FILE_APPEND
    );
    
    $file_tmp = $_FILES['foto_usg']['tmp_name'];
    $file_ext = strtolower(pathinfo($_FILES['foto_usg']['name'], PATHINFO_EXTENSION));
    $allowed_ext = ['jpg', 'jpeg', 'png', 'gif'];
    
    if (in_array($file_ext, $allowed_ext)) {
        // Generate filename: usg_YYYYMMDD_HHMMSS.ext
        $foto_usg_filename = 'usg_' . date('Ymd_His') . '.' . $file_ext;
        $file_path = $upload_dir . $foto_usg_filename;
        
        if (!move_uploaded_file($file_tmp, $file_path)) {
            $error_msg = 'Failed to upload foto USG to: ' . $file_path;
            file_put_contents($upload_dir . 'debug.log', 
                date('Y-m-d H:i:s') . " - ERROR: " . $error_msg . "\n" .
                "is_uploaded_file: " . (is_uploaded_file($file_tmp) ? 'yes' : 'no') . "\n" .
                "is_writable: " . (is_writable($upload_dir) ? 'yes' : 'no') . "\n\n",
                FILE_APPEND
            );
            echo json_encode(['status' => 'error', 'message' => $error_msg]);
            exit;
        }
        
        file_put_contents($upload_dir . 'debug.log', 
            date('Y-m-d H:i:s') . " - SUCCESS: Uploaded " . $foto_usg_filename . " to " . $file_path . "\n\n",
            FILE_APPEND
        );
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Invalid file type. Only JPG, PNG, GIF allowed']);
        exit;
    }
} else {
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/my_pregnancy_api/uploads/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    file_put_contents($upload_dir . 'debug.log', 
        date('Y-m-d H:i:s') . " - WARNING: No file uploaded\n" .
        "FILES array: " . print_r($_FILES, true) . "\n\n",
        FILE_APPEND
    );
}

$input = json_decode(file_get_contents('php://input'), true);
// Jika tidak pakai JSON body, gunakan $_POST (untuk multipart form-data)
if (empty($input)) {
    $input = $_POST;
}

$required = ['tekanan_darah', 'berat_badan', 'tanggal_pemeriksaan'];
foreach ($required as $field) {
    if (!isset($input[$field]) || trim($input[$field]) === '') {
        echo json_encode(['status' => 'error', 'message' => "Field '$field' required"]);
        exit;
    }
}

$stmt = $conn->prepare("INSERT INTO data_ibu (
    tekanan_darah, berat_badan, tinggi_fundus, keluhan, pergerakan_janin, tanggal_pemeriksaan,
    jenis_kunjungan, trimester, hasil_lab, hasil_usg, imunisasi_tt, catatan_anc, gambar
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

$tekanan = $input['tekanan_darah'];
$berat = $input['berat_badan'];
$tinggi = $input['tinggi_fundus'] ?? null;
$keluhan = $input['keluhan'] ?? '';
$pergerakan = $input['pergerakan_janin'] ?? '';
$tanggal = $input['tanggal_pemeriksaan'];
$jenis = $input['jenis_kunjungan'] ?? '';
$trimester = $input['trimester'] ?? '';
$lab = $input['hasil_lab'] ?? '';
$usg = $input['hasil_usg'] ?? '';
$tt = $input['imunisasi_tt'] ?? '';
$catatan = $input['catatan_anc'] ?? '';

$stmt->bind_param(
    "sssssssssssss",
    $tekanan, $berat, $tinggi, $keluhan, $pergerakan, $tanggal,
    $jenis, $trimester, $lab, $usg, $tt, $catatan, $foto_usg_filename
);

if ($stmt->execute()) {
    file_put_contents($upload_dir . 'debug.log', 
        date('Y-m-d H:i:s') . " - DB INSERT SUCCESS with gambar: " . ($foto_usg_filename ?? 'null') . "\n\n",
        FILE_APPEND
    );
    echo json_encode([
        'status' => 'success', 
        'message' => 'Data ibu berhasil disimpan',
        'gambar' => $foto_usg_filename
    ]);
} else {
    file_put_contents($upload_dir . 'debug.log', 
        date('Y-m-d H:i:s') . " - DB INSERT ERROR: " . $stmt->error . "\n\n",
        FILE_APPEND
    );
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
