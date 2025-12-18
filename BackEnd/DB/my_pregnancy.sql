-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Dec 18, 2025 at 02:22 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `my_pregnancy`
--

-- --------------------------------------------------------

--
-- Table structure for table `data_ibu`
--

CREATE TABLE `data_ibu` (
  `id` int NOT NULL,
  `tekanan_darah` varchar(50) DEFAULT NULL,
  `berat_badan` varchar(50) DEFAULT NULL,
  `keluhan` text,
  `pergerakan_janin` text,
  `tanggal_pemeriksaan` date DEFAULT NULL,
  `jenis_kunjungan` varchar(100) DEFAULT NULL,
  `trimester` varchar(50) DEFAULT NULL,
  `hasil_lab` text,
  `hasil_usg` text,
  `imunisasi_tt` varchar(50) DEFAULT NULL,
  `catatan_anc` text,
  `tinggi_fundus` int DEFAULT NULL,
  `kadar_hb` varchar(50) DEFAULT NULL,
  `gambar` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `data_ibu`
--

INSERT INTO `data_ibu` (`id`, `tekanan_darah`, `berat_badan`, `keluhan`, `pergerakan_janin`, `tanggal_pemeriksaan`, `jenis_kunjungan`, `trimester`, `hasil_lab`, `hasil_usg`, `imunisasi_tt`, `catatan_anc`, `tinggi_fundus`, `kadar_hb`, `gambar`, `created_at`) VALUES
(15, '120/79', '57', 'tst', 'tst', '2025-12-14', 'Kunjungan Rutin', 'Trimester I', 'tst', 'tst', 'Belum', 'tst', 15, NULL, NULL, '2025-12-14 03:28:02'),
(16, '110/55', '55', 'asd', 'asd', '2025-12-15', 'Kunjungan Rutin', 'Trimester I', 'asd', 'asd', 'Belum', 'asd', 5, NULL, NULL, '2025-12-15 10:35:40');

-- --------------------------------------------------------

--
-- Table structure for table `fcm_tokens`
--

CREATE TABLE `fcm_tokens` (
  `id` int NOT NULL,
  `id_ibu` int NOT NULL,
  `fcm_token` varchar(255) NOT NULL,
  `device_info` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jadwal_anc`
--

CREATE TABLE `jadwal_anc` (
  `id` int NOT NULL,
  `minggu` varchar(10) NOT NULL,
  `judul` varchar(100) NOT NULL,
  `tanggal` date NOT NULL,
  `jam` varchar(5) DEFAULT '09:00',
  `catatan` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `jadwal_anc`
--

INSERT INTO `jadwal_anc` (`id`, `minggu`, `judul`, `tanggal`, `jam`, `catatan`, `created_at`) VALUES
(5, '1', 'Rutinan 1', '2025-12-18', '21:15', 'Bawa Usg', '2025-12-15 10:38:21');

-- --------------------------------------------------------

--
-- Table structure for table `jurnal_ibu`
--

CREATE TABLE `jurnal_ibu` (
  `id` int NOT NULL,
  `judul` varchar(200) NOT NULL,
  `tanggal` date NOT NULL,
  `catatan` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `jurnal_ibu`
--

INSERT INTO `jurnal_ibu` (`id`, `judul`, `tanggal`, `catatan`, `created_at`) VALUES
(1, 'tst', '2025-12-18', 'tst', '2025-12-18 14:12:38');

-- --------------------------------------------------------

--
-- Table structure for table `notification_log`
--

CREATE TABLE `notification_log` (
  `id` int NOT NULL,
  `id_jadwal` int DEFAULT NULL,
  `id_ibu` int NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('sent','failed') DEFAULT 'sent',
  `fcm_response` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `profil_ibu`
--

CREATE TABLE `profil_ibu` (
  `id` int NOT NULL,
  `nama` varchar(150) NOT NULL,
  `usia_ibu` varchar(10) NOT NULL,
  `usia_kehamilan` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `fcm_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `profil_ibu`
--

INSERT INTO `profil_ibu` (`id`, `nama`, `usia_ibu`, `usia_kehamilan`, `created_at`, `updated_at`, `fcm_token`) VALUES
(1, 'Sarah', '21', '2', '2025-12-13 04:34:41', '2025-12-18 11:21:55', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `data_ibu`
--
ALTER TABLE `data_ibu`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `fcm_tokens`
--
ALTER TABLE `fcm_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_ibu_token` (`id_ibu`,`fcm_token`),
  ADD KEY `idx_fcm_token` (`fcm_token`),
  ADD KEY `idx_ibu_active` (`id_ibu`,`is_active`);

--
-- Indexes for table `jadwal_anc`
--
ALTER TABLE `jadwal_anc`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jurnal_ibu`
--
ALTER TABLE `jurnal_ibu`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notification_log`
--
ALTER TABLE `notification_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notification_ibu` (`id_ibu`),
  ADD KEY `idx_notification_jadwal` (`id_jadwal`),
  ADD KEY `idx_notification_status` (`status`,`sent_at`);

--
-- Indexes for table `profil_ibu`
--
ALTER TABLE `profil_ibu`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `data_ibu`
--
ALTER TABLE `data_ibu`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `fcm_tokens`
--
ALTER TABLE `fcm_tokens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jadwal_anc`
--
ALTER TABLE `jadwal_anc`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `jurnal_ibu`
--
ALTER TABLE `jurnal_ibu`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `notification_log`
--
ALTER TABLE `notification_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `profil_ibu`
--
ALTER TABLE `profil_ibu`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `fcm_tokens`
--
ALTER TABLE `fcm_tokens`
  ADD CONSTRAINT `fcm_tokens_ibfk_1` FOREIGN KEY (`id_ibu`) REFERENCES `profil_ibu` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notification_log`
--
ALTER TABLE `notification_log`
  ADD CONSTRAINT `notification_log_ibfk_1` FOREIGN KEY (`id_ibu`) REFERENCES `profil_ibu` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notification_log_ibfk_2` FOREIGN KEY (`id_jadwal`) REFERENCES `jadwal_anc` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
