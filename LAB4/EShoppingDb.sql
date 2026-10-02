-- 1. Tạo DATABASE
IF DB_ID('EShoppingDB') IS NOT NULL
BEGIN
    ALTER DATABASE EShoppingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EShoppingDB;
END
GO

CREATE DATABASE EShoppingDB;
GO

USE EShoppingDB;
GO

-- 2. BẢNG KHÁCH HÀNG
CREATE TABLE KhachHang
(
    MaKH INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    NgaySinh DATE,
    CMNDPassport VARCHAR(30),
    DiaChi NVARCHAR(255),
    SoDienThoai VARCHAR(15),
    TenDangNhap VARCHAR(50) NOT NULL UNIQUE,
    MatKhau VARCHAR(255) NOT NULL,
    Email VARCHAR(100)
);
GO

-- 3. BẢNG NHÓM SẢN PHẨM
CREATE TABLE NhomSanPham
(
    MaNhomSP INT IDENTITY(1,1) PRIMARY KEY,
    TenNhom NVARCHAR(100) NOT NULL
);
GO

-- 4. BẢNG SẢN PHẨM
CREATE TABLE SanPham
(
    MaSP INT IDENTITY(1,1) PRIMARY KEY,
    TenSP NVARCHAR(200) NOT NULL,
    MaNhomSP INT NOT NULL,
    NhaSanXuat NVARCHAR(100),
    HinhAnh NVARCHAR(255),
    MoTa NVARCHAR(MAX),
    ThongSoKyThuat NVARCHAR(MAX),
    GiaBan DECIMAL(18,2) NOT NULL,
    SoLuongTon INT NOT NULL DEFAULT 0,
    TrangThai NVARCHAR(50),

    CONSTRAINT FK_SanPham_NhomSanPham
        FOREIGN KEY (MaNhomSP)
        REFERENCES NhomSanPham(MaNhomSP),

    CONSTRAINT CK_SanPham_GiaBan
        CHECK (GiaBan >= 0),

    CONSTRAINT CK_SanPham_SoLuongTon
        CHECK (SoLuongTon >= 0)
);
GO

-- 5. BẢNG GIỎ HÀNG
CREATE TABLE GioHang
(
    MaGioHang INT IDENTITY(1,1) PRIMARY KEY,
    MaKH INT NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_GioHang_KhachHang
        FOREIGN KEY (MaKH)
        REFERENCES KhachHang(MaKH),

    CONSTRAINT UQ_GioHang_MaKH
        UNIQUE (MaKH)
);
GO

-- 6. BẢNG CHI TIẾT GIỎ HÀNG
CREATE TABLE ChiTietGioHang
(
    MaGioHang INT NOT NULL,
    MaSP INT NOT NULL,
    SoLuong INT NOT NULL,

    CONSTRAINT PK_ChiTietGioHang
        PRIMARY KEY (MaGioHang, MaSP),

    CONSTRAINT FK_ChiTietGioHang_GioHang
        FOREIGN KEY (MaGioHang)
        REFERENCES GioHang(MaGioHang),

    CONSTRAINT FK_ChiTietGioHang_SanPham
        FOREIGN KEY (MaSP)
        REFERENCES SanPham(MaSP),

    CONSTRAINT CK_ChiTietGioHang_SoLuong
        CHECK (SoLuong > 0)
);
GO

-- 7. BẢNG LOẠI GIAO HÀNG
CREATE TABLE LoaiGiaoHang
(
    MaLoaiGiaoHang INT IDENTITY(1,1) PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL,
    ThoiGianXuLy NVARCHAR(100),
    PhiCoBan DECIMAL(18,2) NOT NULL DEFAULT 0,

    CONSTRAINT CK_LoaiGiaoHang_Phi
        CHECK (PhiCoBan >= 0)
);
GO

-- 8. BẢNG NGƯỜI NHẬN
CREATE TABLE NguoiNhan
(
    MaNguoiNhan INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(255) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL
);
GO

-- 9. BẢNG ĐƠN HÀNG
CREATE TABLE DonHang
(
    MaDonHang INT IDENTITY(1,1) PRIMARY KEY,

    MaKH INT NOT NULL,
    MaNguoiNhan INT NOT NULL,
    MaLoaiGiaoHang INT NOT NULL,

    TongTienHang DECIMAL(18,2) NOT NULL,
PhiGiaoHang DECIMAL(18,2) NOT NULL DEFAULT 0,
    TongThanhToan DECIMAL(18,2) NOT NULL,

    ThoiDiemDat DATETIME NOT NULL DEFAULT GETDATE(),

    TrangThai NVARCHAR(50) NOT NULL
        DEFAULT N'Đã đặt',

    CONSTRAINT FK_DonHang_KhachHang
        FOREIGN KEY (MaKH)
        REFERENCES KhachHang(MaKH),

    CONSTRAINT FK_DonHang_NguoiNhan
        FOREIGN KEY (MaNguoiNhan)
        REFERENCES NguoiNhan(MaNguoiNhan),

    CONSTRAINT FK_DonHang_LoaiGiaoHang
        FOREIGN KEY (MaLoaiGiaoHang)
        REFERENCES LoaiGiaoHang(MaLoaiGiaoHang),

    CONSTRAINT CK_DonHang_TongTienHang
        CHECK (TongTienHang >= 0),

    CONSTRAINT CK_DonHang_PhiGiaoHang
        CHECK (PhiGiaoHang >= 0),

    CONSTRAINT CK_DonHang_TongThanhToan
        CHECK (TongThanhToan >= 0)
);
GO

-- 10. BẢNG CHI TIẾT ĐƠN HÀNG
CREATE TABLE ChiTietDonHang
(
    MaDonHang INT NOT NULL,
    MaSP INT NOT NULL,

    SoLuong INT NOT NULL,
    DonGia DECIMAL(18,2) NOT NULL,

    ThanhTien AS (SoLuong * DonGia) PERSISTED,

    CONSTRAINT PK_ChiTietDonHang
        PRIMARY KEY (MaDonHang, MaSP),

    CONSTRAINT FK_ChiTietDonHang_DonHang
        FOREIGN KEY (MaDonHang)
        REFERENCES DonHang(MaDonHang),

    CONSTRAINT FK_ChiTietDonHang_SanPham
        FOREIGN KEY (MaSP)
        REFERENCES SanPham(MaSP),

    CONSTRAINT CK_ChiTietDonHang_SoLuong
        CHECK (SoLuong > 0),

    CONSTRAINT CK_ChiTietDonHang_DonGia
        CHECK (DonGia >= 0)
);
GO

-- 11. BẢNG THANH TOÁN
CREATE TABLE ThanhToan
(
    MaThanhToan INT IDENTITY(1,1) PRIMARY KEY,

    MaDonHang INT NOT NULL,

    LoaiThe VARCHAR(20),
    SoThe VARCHAR(30),
    NgayHetHan DATE,
    TenChuThe NVARCHAR(100),
    MaBaoMat VARCHAR(10),

    SoTien DECIMAL(18,2) NOT NULL,

    TrangThai NVARCHAR(50) NOT NULL
        DEFAULT N'Chờ thanh toán',

    ThoiDiemThanhToan DATETIME,

    CONSTRAINT FK_ThanhToan_DonHang
        FOREIGN KEY (MaDonHang)
        REFERENCES DonHang(MaDonHang),

    CONSTRAINT UQ_ThanhToan_MaDonHang
        UNIQUE (MaDonHang),

    CONSTRAINT CK_ThanhToan_SoTien
        CHECK (SoTien >= 0)
);
GO

-- DỮ LIỆU MẪU
-- 1. KHÁCH HÀNG
INSERT INTO KhachHang
(HoTen, NgaySinh, CMNDPassport, DiaChi, SoDienThoai, TenDangNhap, MatKhau, Email)
VALUES
(N'Nguyễn Văn An', '2005-05-15', '079205001234', N'TP. Hồ Chí Minh', '0901234567', 'nguyenvanan', '123456', 'an@gmail.com'),
(N'Trần Thị Bình', '2004-08-20', '079204005678', N'TP. Hồ Chí Minh', '0912345678', 'tranthibinh', '123456', 'binh@gmail.com'),
(N'Lê Hoàng Nam', '2005-02-10', '079205009999', N'TP. Hồ Chí Minh', '0923456789', 'lehoangnam', '123456', 'nam@gmail.com'),
(N'Phạm Minh Anh', '2004-11-25', '079204008888', N'TP. Hồ Chí Minh', '0934567890', 'phamminhanh', '123456', 'anh@gmail.com');
GO

-- 2. NHÓM SẢN PHẨM
INSERT INTO NhomSanPham
(TenNhom)
VALUES
(N'Điện thoại'),
(N'Laptop'),
(N'Tai nghe'),
(N'Phụ kiện');
GO

-- 3. SẢN PHẨM
INSERT INTO SanPham
(TenSP, MaNhomSP, NhaSanXuat, HinhAnh, MoTa, ThongSoKyThuat, GiaBan, SoLuongTon, TrangThai)
VALUES
(N'iPhone 17', 1, N'Apple', N'iphone17.jpg', N'Điện thoại thông minh Apple', N'Màn hình 6.3 inch, bộ nhớ 256GB', 24990000, 20, N'Còn hàng'),
(N'Samsung Galaxy S26', 1, N'Samsung', N'samsung-s26.jpg', N'Điện thoại Samsung Galaxy', N'Màn hình AMOLED, bộ nhớ 256GB', 21990000, 15, N'Còn hàng'),
(N'Laptop ASUS Vivobook', 2, N'ASUS', N'asus-vivobook.jpg', N'Laptop phục vụ học tập và làm việc', N'Intel Core i5, RAM 16GB, SSD 512GB', 18990000, 10, N'Còn hàng'),
(N'AirPods Pro', 3, N'Apple', N'airpods-pro.jpg', N'Tai nghe không dây', N'Chống ồn chủ động', 6490000, 25, N'Còn hàng'),
(N'Chuột Logitech', 4, N'Logitech', N'logitech-mouse.jpg', N'Chuột không dây', N'Kết nối Bluetooth', 590000, 50, N'Còn hàng'),
(N'Bàn phím Logitech', 4, N'Logitech', N'logitech-keyboard.jpg', N'Bàn phím không dây', N'Bluetooth, pin sạc', 890000, 30, N'Còn hàng');
GO

-- 4. GIỎ HÀNG
INSERT INTO GioHang
(MaKH, NgayTao)
VALUES
(1, '2026-10-01 08:30:00'),
(2, '2026-10-01 09:15:00'),
(3, '2026-10-01 10:00:00'),
(4, '2026-10-01 10:30:00');
GO

-- 5. CHI TIẾT GIỎ HÀNG
INSERT INTO ChiTietGioHang
(MaGioHang, MaSP, SoLuong)
VALUES
(1, 1, 1),
(1, 5, 2),
(2, 3, 1),
(2, 4, 1),
(3, 2, 1),
(3, 6, 1),
(4, 5, 3);
GO

-- 6. LOẠI GIAO HÀNG
INSERT INTO LoaiGiaoHang
(TenLoai, ThoiGianXuLy, PhiCoBan)
VALUES
(N'Thường', N'3 - 5 ngày', 30000),
(N'Hỏa tốc', N'1 - 2 ngày', 50000),
(N'Hỏa tốc trong ngày', N'Trong ngày', 80000);
GO

-- 7. NGƯỜI NHẬN
INSERT INTO NguoiNhan
(HoTen, DiaChi, SoDienThoai)
VALUES
(N'Nguyễn Văn An', N'123 Nguyễn Trãi, Quận 5, TP. Hồ Chí Minh', '0901234567'),
(N'Trần Thị Bình', N'456 Lê Văn Sỹ, Quận 3, TP. Hồ Chí Minh', '0912345678'),
(N'Lê Hoàng Nam', N'789 Cộng Hòa, Quận Tân Bình, TP. Hồ Chí Minh', '0923456789'),
(N'Phạm Minh Anh', N'25 Điện Biên Phủ, Quận Bình Thạnh, TP. Hồ Chí Minh', '0934567890');
GO

-- 8. ĐƠN HÀNG
INSERT INTO DonHang
(MaKH, MaNguoiNhan, MaLoaiGiaoHang, TongTienHang, PhiGiaoHang, TongThanhToan, ThoiDiemDat, TrangThai)
VALUES
(1, 1, 1, 26170000, 0, 26170000, '2026-10-01 14:30:00', N'Đã đặt'),
(2, 2, 2, 25480000, 0, 25480000, '2026-10-01 15:00:00', N'Đã đặt'),
(3, 3, 1, 22880000, 0, 22880000, '2026-10-01 16:15:00', N'Đã đặt'),
(4, 4, 3, 1770000, 80000, 1850000, '2026-10-01 17:00:00', N'Đã đặt');
GO

-- 9. CHI TIẾT ĐƠN HÀNG
INSERT INTO ChiTietDonHang
(MaDonHang, MaSP, SoLuong, DonGia)
VALUES
(1, 1, 1, 24990000),
(1, 5, 3, 590000),
(2, 3, 1, 18990000),
(2, 4, 1, 6490000),
(3, 2, 1, 21990000),
(3, 6, 1, 890000),
(4, 5, 3, 590000);
GO

-- 10. THANH TOÁN
INSERT INTO ThanhToan
(MaDonHang, LoaiThe, SoThe, NgayHetHan, TenChuThe, MaBaoMat, SoTien, TrangThai, ThoiDiemThanhToan)
VALUES
(1, 'VISA', '4111111111111111', '2028-05-31', N'NGUYEN VAN AN', '123', 26170000, N'Thành công', '2026-10-01 14:32:00'),
(2, 'Master', '5555555555554444', '2029-08-31', N'TRAN THI BINH', '456', 25480000, N'Thành công', '2026-10-01 15:02:00'),
(3, 'Discover', '6011111111111117', '2028-12-31', N'LE HOANG NAM', '789', 22880000, N'Thành công', '2026-10-01 16:17:00'),
(4, 'AmEx', '378282246310005', '2029-06-30', N'PHAM MINH ANH', '321', 1850000, N'Thành công', '2026-10-01 17:02:00');
GO
