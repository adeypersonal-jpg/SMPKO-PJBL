-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 18, 2026 at 07:24 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `smpko`
--
CREATE DATABASE IF NOT EXISTS `smpko` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `smpko`;

-- --------------------------------------------------------

--
-- Table structure for table `kendaraan`
--

CREATE TABLE `kendaraan` (
  `id_kendaraan` varchar(10) NOT NULL,
  `id_pengguna` varchar(10) DEFAULT NULL,
  `no_plat` varchar(20) DEFAULT NULL,
  `jenis` varchar(50) DEFAULT NULL,
  `merek` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pengguna`
--

CREATE TABLE `pengguna` (
  `id_pengguna` varchar(10) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `profesi` enum('Mahasiswa','Dosen','Pegawai') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sesi_parkir`
--

CREATE TABLE `sesi_parkir` (
  `id_sesi` varchar(10) NOT NULL,
  `id_kendaraan` varchar(10) DEFAULT NULL,
  `id_slot` varchar(10) DEFAULT NULL,
  `waktu_masuk` datetime DEFAULT NULL,
  `waktu_keluar` datetime DEFAULT NULL,
  `status` enum('Aktif','Selesai') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `sesi_parkir`
--
DELIMITER $$
CREATE TRIGGER `trg_keluar` BEFORE UPDATE ON `sesi_parkir` FOR EACH ROW BEGIN
    IF OLD.status = 'Aktif'
       AND NEW.status = 'Selesai' THEN

        SET NEW.waktu_keluar = NOW();

        UPDATE slot_parkir
        SET status_sensor = 'Mati'
        WHERE id_slot = OLD.id_slot;

    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Sesi parkir belum aktif atau sudah selesai';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_setelah_masuk` AFTER INSERT ON `sesi_parkir` FOR EACH ROW BEGIN
    UPDATE slot_parkir
    SET status_sensor = 'Hidup'
    WHERE id_slot = NEW.id_slot;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_validasi` BEFORE INSERT ON `sesi_parkir` FOR EACH ROW BEGIN
    DECLARE v_jenis_kendaraan VARCHAR(50);
    DECLARE v_jenis_tempat VARCHAR(50);

    SELECT jenis
    INTO v_jenis_kendaraan
    FROM kendaraan
    WHERE id_kendaraan = NEW.id_kendaraan;

    SELECT tp.jenis
    INTO v_jenis_tempat
    FROM slot_parkir sp
    JOIN tempat_parkir tp
        ON sp.id_tempat = tp.id_tempat
    WHERE sp.id_slot = NEW.id_slot;

    IF v_jenis_kendaraan <> v_jenis_tempat THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Jenis kendaraan tidak sesuai dengan jenis tempat parkir!';
    END IF;

    IF NEW.status <> 'Aktif' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Status awal sesi parkir harus Aktif!';
    END IF;

    SET NEW.waktu_masuk = NOW();
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `slot_parkir`
--

CREATE TABLE `slot_parkir` (
  `id_slot` varchar(10) NOT NULL,
  `id_tempat` varchar(10) DEFAULT NULL,
  `status_sensor` enum('Hidup','Mati') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `slot_parkir`
--
DELIMITER $$
CREATE TRIGGER `trg_hapus_slot` AFTER DELETE ON `slot_parkir` FOR EACH ROW BEGIN
    UPDATE tempat_parkir
    SET kapasitas = kapasitas - 1
    WHERE id_tempat = OLD.id_tempat;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_tambah_slot` AFTER INSERT ON `slot_parkir` FOR EACH ROW BEGIN
    UPDATE tempat_parkir
    SET kapasitas = kapasitas + 1
    WHERE id_tempat = NEW.id_tempat;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tempat_parkir`
--

CREATE TABLE `tempat_parkir` (
  `id_tempat` varchar(10) NOT NULL,
  `lokasi` varchar(100) DEFAULT NULL,
  `jenis` varchar(50) DEFAULT NULL,
  `kapasitas` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_status_parkir`
-- (See below for the actual view)
--
CREATE TABLE `v_status_parkir` (
`id_tempat` varchar(10)
,`lokasi` varchar(100)
,`jenis` varchar(50)
,`kapasitas` int(11)
,`slot_terisi` bigint(21)
,`slot_tersedia` bigint(22)
);

-- --------------------------------------------------------

--
-- Structure for view `v_status_parkir`
--
DROP TABLE IF EXISTS `v_status_parkir`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_status_parkir`  AS SELECT `tp`.`id_tempat` AS `id_tempat`, `tp`.`lokasi` AS `lokasi`, `tp`.`jenis` AS `jenis`, `tp`.`kapasitas` AS `kapasitas`, count(`sp`.`id_slot`) AS `slot_terisi`, `tp`.`kapasitas`- count(`sp`.`id_slot`) AS `slot_tersedia` FROM (`tempat_parkir` `tp` left join `slot_parkir` `sp` on(`tp`.`id_tempat` = `sp`.`id_tempat` and `sp`.`status_sensor` = 'Hidup')) GROUP BY `tp`.`id_tempat` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `kendaraan`
--
ALTER TABLE `kendaraan`
  ADD PRIMARY KEY (`id_kendaraan`),
  ADD UNIQUE KEY `idx_plat` (`no_plat`),
  ADD KEY `id_pengguna` (`id_pengguna`);

--
-- Indexes for table `pengguna`
--
ALTER TABLE `pengguna`
  ADD PRIMARY KEY (`id_pengguna`);

--
-- Indexes for table `sesi_parkir`
--
ALTER TABLE `sesi_parkir`
  ADD PRIMARY KEY (`id_sesi`),
  ADD KEY `id_kendaraan` (`id_kendaraan`),
  ADD KEY `id_slot` (`id_slot`);

--
-- Indexes for table `slot_parkir`
--
ALTER TABLE `slot_parkir`
  ADD PRIMARY KEY (`id_slot`),
  ADD KEY `id_tempat` (`id_tempat`);

--
-- Indexes for table `tempat_parkir`
--
ALTER TABLE `tempat_parkir`
  ADD PRIMARY KEY (`id_tempat`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `kendaraan`
--
ALTER TABLE `kendaraan`
  ADD CONSTRAINT `kendaraan_ibfk_1` FOREIGN KEY (`id_pengguna`) REFERENCES `pengguna` (`id_pengguna`);

--
-- Constraints for table `sesi_parkir`
--
ALTER TABLE `sesi_parkir`
  ADD CONSTRAINT `sesi_parkir_ibfk_1` FOREIGN KEY (`id_kendaraan`) REFERENCES `kendaraan` (`id_kendaraan`),
  ADD CONSTRAINT `sesi_parkir_ibfk_2` FOREIGN KEY (`id_slot`) REFERENCES `slot_parkir` (`id_slot`);

--
-- Constraints for table `slot_parkir`
--
ALTER TABLE `slot_parkir`
  ADD CONSTRAINT `slot_parkir_ibfk_1` FOREIGN KEY (`id_tempat`) REFERENCES `tempat_parkir` (`id_tempat`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
