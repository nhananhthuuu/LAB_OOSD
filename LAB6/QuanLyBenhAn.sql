USE master;
GO
IF DB_ID('QuanLyBenhAn') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyBenhAn SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyBenhAn;
END
GO
CREATE DATABASE QuanLyBenhAn;
GO
USE QuanLyBenhAn;
GO
 
-- ---------------------- Nhóm danh mục ----------------------
CREATE TABLE Khoa (
    MaKhoa  VARCHAR(20) PRIMARY KEY,
    TenKhoa NVARCHAR(100) NOT NULL
);
 
CREATE TABLE BacSi (                                   
    MaBS      VARCHAR(20) PRIMARY KEY,
    HoTen     NVARCHAR(100) NOT NULL,
    ChuyenMon NVARCHAR(100),
    MaKhoa    VARCHAR(20) NOT NULL REFERENCES Khoa(MaKhoa)
);
 
CREATE TABLE NhanVienCSKH (
    MaNV        VARCHAR(20) PRIMARY KEY,
    HoTen       NVARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15)
);
 
CREATE TABLE XetNghiem (
    MaXN   VARCHAR(20) PRIMARY KEY,
    TenXN  NVARCHAR(100) NOT NULL,
    DonGia DECIMAL(18,0) NOT NULL DEFAULT 0
);
 
CREATE TABLE Thuoc (
    MaThuoc  VARCHAR(20) PRIMARY KEY,
    TenThuoc NVARCHAR(100) NOT NULL,
    DonVi    NVARCHAR(20),
    DonGia   DECIMAL(18,0) NOT NULL DEFAULT 0
);
 
-- ---------------------- Bệnh nhân & hồ sơ ----------------------
CREATE TABLE BenhNhan (
    MaBN      VARCHAR(20) PRIMARY KEY,
    HoTen     NVARCHAR(100) NOT NULL,
    DiaChi    NVARCHAR(200),
    NgaySinh  DATE,
    DienThoai VARCHAR(15),
    Anh3x4    NVARCHAR(255) NULL                       -- lưu đường dẫn ảnh (string theo sơ đồ)
);
 
CREATE TABLE LePhiNam (                                -- BenhNhan 1 --- 0..* LePhiNam
    MaLePhi   VARCHAR(20) PRIMARY KEY,
    MaBN      VARCHAR(20) NOT NULL REFERENCES BenhNhan(MaBN),
    NamApDung INT NOT NULL,
    SoTien    DECIMAL(18,0) NOT NULL,
    NgayDong  DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_LePhi_BN_Nam UNIQUE (MaBN, NamApDung)   -- mỗi năm đóng 1 lần
);
 
CREATE TABLE HoSoBenhAn (                              -- BenhNhan 1 --- 1 HoSoBenhAn
    MaHoSo     VARCHAR(20) PRIMARY KEY,
    MaBN       VARCHAR(20) NOT NULL UNIQUE REFERENCES BenhNhan(MaBN),
    NgayCap    DATE NOT NULL DEFAULT GETDATE(),
    NgayHetHan DATE NOT NULL
);
 
CREATE TABLE LichKhamDinhKy (                          -- BenhNhan 1 --- 0..* LichKhamDinhKy
    MaLich     VARCHAR(20) PRIMARY KEY,
    MaBN       VARCHAR(20) NOT NULL REFERENCES BenhNhan(MaBN),
    Quy        INT NOT NULL CHECK (Quy BETWEEN 1 AND 4),
    Nam        INT NOT NULL,
    NgayGioHen DATETIME NOT NULL,
    TrangThai  NVARCHAR(30) NOT NULL DEFAULT N'Đã hẹn',   -- Đã hẹn / Đã khám / Đã hủy
    CONSTRAINT UQ_Lich_BN_Quy_Nam UNIQUE (MaBN, Quy, Nam) -- mỗi quý khám 1 lần
);
 
-- ---------------------- Khám bệnh ----------------------
CREATE TABLE PhieuKham (
    MaPK        VARCHAR(20) PRIMARY KEY,
    MaHoSo      VARCHAR(20) NOT NULL REFERENCES HoSoBenhAn(MaHoSo),   -- composition: 1 --- 0..*
    MaBS        VARCHAR(20) NOT NULL REFERENCES BacSi(MaBS),
    MaKhoa      VARCHAR(20) NOT NULL REFERENCES Khoa(MaKhoa),
    MaNV        VARCHAR(20) NULL REFERENCES NhanVienCSKH(MaNV),       -- NV ghi nhận phiếu
    MaLich      VARCHAR(20) NULL REFERENCES LichKhamDinhKy(MaLich),   -- 0..1 --- 0..1
    NgayGioKham DATETIME NOT NULL DEFAULT GETDATE(),
    TrieuChung  NVARCHAR(500),
    NhietDo     FLOAT NULL,
    HuyetAp     NVARCHAR(20) NULL,
    LoaiKham    NVARCHAR(30) NOT NULL DEFAULT N'Điều trị'
                CHECK (LoaiKham IN (N'Điều trị', N'Định kỳ')),
    TrangThai   NVARCHAR(30) NOT NULL DEFAULT N'Đang khám'            -- Đang khám / Hoàn tất
);
-- 1 lịch hẹn chỉ gắn với tối đa 1 phiếu khám
CREATE UNIQUE INDEX UX_PhieuKham_MaLich ON PhieuKham(MaLich) WHERE MaLich IS NOT NULL;
 
CREATE TABLE ChiDinhXN (                               -- PhieuKham 1 --- 0..* ChiDinhXN *--- 1 XetNghiem
    MaChiDinh   VARCHAR(20) PRIMARY KEY,
    MaPK        VARCHAR(20) NOT NULL REFERENCES PhieuKham(MaPK) ON DELETE CASCADE,
    MaXN        VARCHAR(20) NOT NULL REFERENCES XetNghiem(MaXN),
    NgayThucHien DATETIME NULL,
    KetQua      NVARCHAR(300) NULL
);
 
CREATE TABLE ToaThuoc (                                -- PhieuKham 1 --- 0..1 ToaThuoc
    MaToa   VARCHAR(20) PRIMARY KEY,
    MaPK    VARCHAR(20) NOT NULL UNIQUE REFERENCES PhieuKham(MaPK),
    NgayLap DATETIME NOT NULL DEFAULT GETDATE(),
    GhiChu  NVARCHAR(300)
);
 
CREATE TABLE ChiTietToa (                              -- ToaThuoc 1 <>--- 1..* ChiTietToa *--- 1 Thuoc
    MaCT     VARCHAR(20) PRIMARY KEY,
    MaToa    VARCHAR(20) NOT NULL REFERENCES ToaThuoc(MaToa) ON DELETE CASCADE,
    MaThuoc  VARCHAR(20) NOT NULL REFERENCES Thuoc(MaThuoc),
    SoLuong  INT NOT NULL CHECK (SoLuong > 0),
    LieuDung NVARCHAR(100),
    CachDung NVARCHAR(200),
    CONSTRAINT UQ_ChiTietToa UNIQUE (MaToa, MaThuoc)
);
 
CREATE TABLE HoaDon (                                  -- PhieuKham 1 --- 0..1 HoaDon
    MaHD          VARCHAR(20) PRIMARY KEY,
    MaPK          VARCHAR(20) NOT NULL UNIQUE REFERENCES PhieuKham(MaPK),
    TongTien      DECIMAL(18,0) NOT NULL,
    NgayThanhToan DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai     NVARCHAR(30) NOT NULL DEFAULT N'Đã thanh toán'
);
GO
 
-- =====================================================================
-- STORED PROCEDURE / FUNCTION
-- =====================================================================
-- Tìm hồ sơ theo mã hồ sơ / mã BN / họ tên / điện thoại (traCuu)
CREATE PROCEDURE sp_TimHoSo @TuKhoa NVARCHAR(100)
AS
BEGIN
    SELECT h.MaHoSo, b.MaBN, b.HoTen, b.NgaySinh, b.DienThoai,
           h.NgayCap, h.NgayHetHan,
           CASE WHEN h.NgayHetHan >= CAST(GETDATE() AS DATE)
                THEN N'Còn hạn' ELSE N'Hết hạn' END AS TinhTrang
    FROM HoSoBenhAn h JOIN BenhNhan b ON h.MaBN = b.MaBN
    WHERE h.MaHoSo LIKE '%' + @TuKhoa + '%'
       OR b.MaBN   LIKE '%' + @TuKhoa + '%'
       OR b.HoTen  LIKE N'%' + @TuKhoa + N'%'
       OR b.DienThoai LIKE '%' + @TuKhoa + '%';
END
GO
 
-- Lịch sử khám của 1 hồ sơ (xemLichSu)
CREATE PROCEDURE sp_LichSuKham @MaHoSo VARCHAR(20)
AS
BEGIN
    SELECT p.MaPK, p.NgayGioKham, p.LoaiKham, bs.HoTen AS BacSi, k.TenKhoa,
           p.TrieuChung, p.NhietDo, p.HuyetAp, p.TrangThai
    FROM PhieuKham p
    JOIN BacSi bs ON p.MaBS = bs.MaBS
    JOIN Khoa  k  ON p.MaKhoa = k.MaKhoa
    WHERE p.MaHoSo = @MaHoSo
    ORDER BY p.NgayGioKham DESC;
END
GO
 
-- Tính tổng viện phí của 1 phiếu khám = tiền thuốc + tiền xét nghiệm
CREATE FUNCTION fn_TongVienPhi (@MaPK VARCHAR(20))
RETURNS DECIMAL(18,0)
AS
BEGIN
    DECLARE @thuoc DECIMAL(18,0), @xn DECIMAL(18,0);
    SELECT @thuoc = ISNULL(SUM(c.SoLuong * t.DonGia), 0)
    FROM ToaThuoc tt
    JOIN ChiTietToa c ON c.MaToa = tt.MaToa
    JOIN Thuoc t      ON t.MaThuoc = c.MaThuoc
    WHERE tt.MaPK = @MaPK;
 
    SELECT @xn = ISNULL(SUM(x.DonGia), 0)
    FROM ChiDinhXN d JOIN XetNghiem x ON x.MaXN = d.MaXN
    WHERE d.MaPK = @MaPK;
 
    RETURN @thuoc + @xn;
END
GO
 
-- =====================================================================
-- DỮ LIỆU MẪU
-- =====================================================================
INSERT Khoa VALUES ('K01', N'Nội tổng quát'), ('K02', N'Nhi'), ('K03', N'Tim mạch');
 
INSERT BacSi VALUES ('BS01', N'Nguyễn Văn An',   N'Nội khoa',  'K01'),
                    ('BS02', N'Trần Thị Bình',   N'Nhi khoa',  'K02'),
                    ('BS03', N'Lê Hoàng Cường',  N'Tim mạch',  'K03');
 
INSERT NhanVienCSKH VALUES ('NV01', N'Phạm Thu Hà', '0901234567'),
                           ('NV02', N'Võ Minh Khoa', '0907654321');
 
INSERT XetNghiem VALUES ('XN01', N'Xét nghiệm máu', 150000),
                        ('XN02', N'Siêu âm bụng',   200000),
                        ('XN03', N'Điện tim (ECG)', 120000);
 
INSERT Thuoc VALUES ('T01', N'Paracetamol 500mg', N'Viên', 2000),
                    ('T02', N'Amoxicillin 500mg', N'Viên', 5000),
                    ('T03', N'Vitamin C 500mg',   N'Viên', 1500);
 
INSERT BenhNhan (MaBN, HoTen, DiaChi, NgaySinh, DienThoai)
VALUES ('BN001', N'Nguyễn Minh Tuấn', N'Q.1, TP.HCM', '1995-05-12', '0912345678');
 
INSERT LePhiNam (MaLePhi, MaBN, NamApDung, SoTien)
VALUES ('LP001', 'BN001', YEAR(GETDATE()), 500000);
 
INSERT HoSoBenhAn (MaHoSo, MaBN, NgayCap, NgayHetHan)
VALUES ('HS001', 'BN001', CAST(GETDATE() AS DATE), DATEADD(YEAR, 1, CAST(GETDATE() AS DATE)));
GO