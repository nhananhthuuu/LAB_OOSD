USE master;
GO
IF DB_ID(N'QuanLyNhanSu_DongA') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyNhanSu_DongA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyNhanSu_DongA;
END
GO
CREATE DATABASE QuanLyNhanSu_DongA;
GO
USE QuanLyNhanSu_DongA;
GO

CREATE TABLE PhongBan (
    maPB  VARCHAR(10)   NOT NULL PRIMARY KEY,
    tenPB NVARCHAR(100) NOT NULL
);

CREATE TABLE NhanVien (
    maNV   VARCHAR(10)   NOT NULL PRIMARY KEY,
    hoTen  NVARCHAR(100) NOT NULL,
    maPB   VARCHAR(10)   NOT NULL,
    chucVu NVARCHAR(50)  NULL,
    CONSTRAINT FK_NV_PB FOREIGN KEY (maPB) REFERENCES PhongBan(maPB)
);

CREATE TABLE QuyetDinhKhenThuong (
    maQD          VARCHAR(10)   NOT NULL PRIMARY KEY,
    loaiDoiTuong  NVARCHAR(20)  NOT NULL
        CHECK (loaiDoiTuong IN (N'CaNhan', N'TapThe')),
    maNV          VARCHAR(10)   NULL,
    maPB          VARCHAR(10)   NULL,
    loaiThuong    NVARCHAR(50)  NOT NULL,
    noiDung       NVARCHAR(500) NOT NULL,
    soTien        DECIMAL(18,0) NOT NULL CHECK (soTien > 0),
    ngayQD        DATE          NOT NULL,
    trangThai     NVARCHAR(20)  NOT NULL DEFAULT N'ChoDuyet'
        CHECK (trangThai IN (N'ChoDuyet', N'DaDuyet', N'TuChoi')),
    CONSTRAINT FK_QD_NV FOREIGN KEY (maNV) REFERENCES NhanVien(maNV),
    CONSTRAINT FK_QD_PB FOREIGN KEY (maPB) REFERENCES PhongBan(maPB),
    CONSTRAINT CK_QD_DoiTuong CHECK (
        (loaiDoiTuong = N'CaNhan' AND maNV IS NOT NULL AND maPB IS NULL) OR
        (loaiDoiTuong = N'TapThe' AND maPB IS NOT NULL AND maNV IS NULL))
);

CREATE TABLE PhieuChiKhenThuong (
    maPC   VARCHAR(10)   NOT NULL PRIMARY KEY,
    maQD   VARCHAR(10)   NOT NULL UNIQUE,   -- mỗi quyết định chỉ có 1 phiếu chi
    soTien DECIMAL(18,0) NOT NULL,
    ngayChi DATE         NOT NULL,
    CONSTRAINT FK_PC_QD FOREIGN KEY (maQD) REFERENCES QuyetDinhKhenThuong(maQD)
);
GO

-- Dữ liệu mẫu
INSERT INTO PhongBan VALUES
 ('PB01', N'Phòng Nhân sự'),
 ('PB02', N'Phòng Kinh doanh'),
 ('PB03', N'Phòng Sản xuất');

INSERT INTO NhanVien VALUES
 ('NV001', N'Nguyễn Văn An',   'PB01', N'Trưởng phòng'),
 ('NV002', N'Trần Thị Bình',   'PB01', N'Nhân viên'),
 ('NV003', N'Lê Hoàng Cường',  'PB02', N'Trưởng phòng'),
 ('NV004', N'Phạm Thị Dung',   'PB02', N'Nhân viên'),
 ('NV005', N'Võ Minh Em',      'PB03', N'Quản đốc'),
 ('NV006', N'Đặng Quốc Phú',   'PB03', N'Công nhân');

INSERT INTO QuyetDinhKhenThuong VALUES
 ('QD001', N'CaNhan', 'NV003', NULL,   N'Thưởng thành tích', N'Vượt chỉ tiêu doanh số quý 3', 5000000, '2026-10-01', N'DaDuyet'),
 ('QD002', N'CaNhan', 'NV006', NULL,   N'Thưởng lễ',         N'Thưởng lễ Quốc khánh',          1000000, '2026-10-10', N'ChoDuyet'),
 ('QD003', N'TapThe', NULL,   'PB03',  N'Thưởng cuối năm',   N'Hoàn thành kế hoạch sản xuất',  20000000, '2026-10-15', N'ChoDuyet');

INSERT INTO PhieuChiKhenThuong VALUES
 ('PC001', 'QD001', 5000000, '2026-10-02');
GO

SELECT * FROM QuyetDinhKhenThuong;