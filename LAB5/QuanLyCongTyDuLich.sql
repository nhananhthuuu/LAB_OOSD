/* =====================================================================
   CSDL: QUẢN LÝ CÔNG TY DU LỊCH VĂN HÓA VIỆT   (SQL Server / T-SQL)
   Chuyển từ Class Diagram sang bảng.

   KẾ THỪA KhachHang: dùng "bảng cha + 2 bảng con"
     - KhachHang (cha, có cột LoaiKH = 'DOAN' | 'LE')
     - KhachDoan, KhachLe (con): PK = FK về KhachHang
     - FK ghép (MaKH, LoaiKH) để 1 khách không thể vừa là đoàn vừa là lẻ.

   GIẢ ĐỊNH: khách đoàn  > 12 người, khách lẻ  1..12 người
             (đề chưa nói rõ đúng 12 người, sửa ở 2 CHECK SoNguoi nếu cần)
   ===================================================================== */
SET QUOTED_IDENTIFIER ON;   -- cần cho filtered index
GO
IF DB_ID(N'QuanLyDuLich') IS NULL CREATE DATABASE QuanLyDuLich;
GO
USE QuanLyDuLich;
GO

/* ---------- 0. Xóa cũ (chạy lại nhiều lần được) ---------- */
DROP FUNCTION IF EXISTS dbo.fn_KiemTraChongCheo;
DROP FUNCTION IF EXISTS dbo.fn_TinhLuongThang;
DROP FUNCTION IF EXISTS dbo.fn_TinhGiaTour;
DROP TABLE IF EXISTS PhanCong;
DROP TABLE IF EXISTS ThanhVienDoan;
DROP TABLE IF EXISTS PhieuDangKyChuyen;
DROP TABLE IF EXISTS PhieuDangKyDoan;
DROP TABLE IF EXISTS TourDiemThamQuan;
DROP TABLE IF EXISTS DiemThamQuan;
DROP TABLE IF EXISTS DiemDung;
DROP TABLE IF EXISTS PhuongTien;
DROP TABLE IF EXISTS ChuyenDi;
DROP TABLE IF EXISTS Tour;
DROP TABLE IF EXISTS DiemBanVe;
DROP TABLE IF EXISTS PhieuKhaoSat;
DROP TABLE IF EXISTS KhachDoan;
DROP TABLE IF EXISTS KhachLe;
DROP TABLE IF EXISTS KhachHang;
DROP TABLE IF EXISTS NhanVien;
GO

/* =====================================================================
   1. TẠO BẢNG
   ===================================================================== */

/* ---- NhanVien ---- (ChucVu: cột bổ sung để phân biệt HDV / bán vé / quản lý
        như các Actor trong Use Case; không có trong Class Diagram) */
CREATE TABLE NhanVien (
    MaNV        VARCHAR(10)   NOT NULL CONSTRAINT PK_NhanVien PRIMARY KEY,
    HoTen       NVARCHAR(100) NOT NULL,
    ChucVu      NVARCHAR(30)  NOT NULL CONSTRAINT DF_NV_ChucVu DEFAULT N'Hướng dẫn viên',
    LuongCoBan  DECIMAL(15,0) NOT NULL CONSTRAINT CK_NV_Luong CHECK (LuongCoBan >= 0),
    CONSTRAINT CK_NV_ChucVu CHECK (ChucVu IN (N'Hướng dẫn viên', N'Nhân viên bán vé', N'Quản lý'))
);

/* ---- KhachHang (bảng cha) ---- */
CREATE TABLE KhachHang (
    MaKH       VARCHAR(10)   NOT NULL CONSTRAINT PK_KhachHang PRIMARY KEY,
    LoaiKH     CHAR(4)       NOT NULL CONSTRAINT CK_KH_LoaiKH CHECK (LoaiKH IN ('DOAN','LE')),
    TenKH      NVARCHAR(100) NOT NULL,
    DiaChi     NVARCHAR(200) NULL,
    DienThoai  VARCHAR(15)   NOT NULL CONSTRAINT UQ_KH_DienThoai UNIQUE,
    CONSTRAINT UQ_KH_Ma_Loai UNIQUE (MaKH, LoaiKH)      -- để bảng con tham chiếu FK ghép
);

/* ---- KhachDoan (con) ---- */
CREATE TABLE KhachDoan (
    MaKH          VARCHAR(10)   NOT NULL CONSTRAINT PK_KhachDoan PRIMARY KEY,
    LoaiKH        CHAR(4)       NOT NULL CONSTRAINT DF_KD_LoaiKH DEFAULT 'DOAN'
                                CONSTRAINT CK_KD_LoaiKH CHECK (LoaiKH = 'DOAN'),
    NguoiDaiDien  NVARCHAR(100) NOT NULL,
    GhiChuCSKH    NVARCHAR(500) NULL,
    CONSTRAINT FK_KhachDoan_KhachHang FOREIGN KEY (MaKH, LoaiKH)
        REFERENCES KhachHang (MaKH, LoaiKH) ON DELETE CASCADE
);

/* ---- KhachLe (con) ---- */
CREATE TABLE KhachLe (
    MaKH    VARCHAR(10) NOT NULL CONSTRAINT PK_KhachLe PRIMARY KEY,
    LoaiKH  CHAR(4)     NOT NULL CONSTRAINT DF_KL_LoaiKH DEFAULT 'LE'
                        CONSTRAINT CK_KL_LoaiKH CHECK (LoaiKH = 'LE'),
    CONSTRAINT FK_KhachLe_KhachHang FOREIGN KEY (MaKH, LoaiKH)
        REFERENCES KhachHang (MaKH, LoaiKH) ON DELETE CASCADE
);

/* ---- PhieuKhaoSat: KhachHang 1 --- 0..* PhieuKhaoSat ---- */
CREATE TABLE PhieuKhaoSat (
    MaPK          VARCHAR(10)    NOT NULL CONSTRAINT PK_PhieuKhaoSat PRIMARY KEY,
    MaKH          VARCHAR(10)    NOT NULL CONSTRAINT FK_PKS_KhachHang REFERENCES KhachHang(MaKH),
    NgayGui       DATETIME       NOT NULL CONSTRAINT DF_PKS_NgayGui DEFAULT GETDATE(),
    NoiDungGopY   NVARCHAR(1000) NULL            -- NULL = khách chưa phản hồi
);

/* ---- Tour ---- */
CREATE TABLE Tour (
    MaTour   VARCHAR(10)   NOT NULL CONSTRAINT PK_Tour PRIMARY KEY,
    TenTour  NVARCHAR(150) NOT NULL CONSTRAINT UQ_Tour_Ten UNIQUE,
    SoNgay   INT           NOT NULL CONSTRAINT CK_Tour_SoNgay CHECK (SoNgay >= 1),
    SoDem    INT           NOT NULL CONSTRAINT CK_Tour_SoDem  CHECK (SoDem >= 0),
    DonGia   DECIMAL(15,0) NOT NULL CONSTRAINT CK_Tour_DonGia CHECK (DonGia > 0),   -- giá / 1 khách
    CONSTRAINT CK_Tour_NgayDem CHECK (SoDem BETWEEN SoNgay - 1 AND SoNgay)
);

/* ---- PhuongTien ---- */
CREATE TABLE PhuongTien (
    MaPT   VARCHAR(10)   NOT NULL CONSTRAINT PK_PhuongTien PRIMARY KEY,
    TenPT  NVARCHAR(50)  NOT NULL CONSTRAINT UQ_PT_Ten UNIQUE
);

/* ---- DiemDung: Tour 1 <>--- 1..* DiemDung (composition), PhuongTien 1 --- 0..* DiemDung ---- */
CREATE TABLE DiemDung (
    MaDiemDung     VARCHAR(10)  NOT NULL CONSTRAINT PK_DiemDung PRIMARY KEY,
    MaTour         VARCHAR(10)  NOT NULL
                   CONSTRAINT FK_DiemDung_Tour REFERENCES Tour(MaTour) ON DELETE CASCADE,
    MaPT           VARCHAR(10)  NOT NULL CONSTRAINT FK_DiemDung_PT REFERENCES PhuongTien(MaPT),
    ThuTu          INT          NOT NULL CONSTRAINT CK_DD_ThuTu CHECK (ThuTu >= 1),
    NoiDen         NVARCHAR(100) NOT NULL,
    DoiPhuongTien  BIT          NOT NULL CONSTRAINT DF_DD_Doi DEFAULT 0,
    CoAn           BIT          NOT NULL CONSTRAINT DF_DD_An  DEFAULT 0,
    CoKhachSan     BIT          NOT NULL CONSTRAINT DF_DD_KS  DEFAULT 0,
    LoaiKhachSan   TINYINT      NULL,
    CONSTRAINT UQ_DD_Tour_ThuTu UNIQUE (MaTour, ThuTu),
    -- có khách sạn thì phải có loại 2-5 sao; không có thì để NULL
    CONSTRAINT CK_DD_KhachSan CHECK (
        (CoKhachSan = 1 AND LoaiKhachSan IN (2,3,4,5)) OR (CoKhachSan = 0 AND LoaiKhachSan IS NULL))
);

/* ---- DiemThamQuan + bảng nối (Tour 0..* --- 1..* DiemThamQuan) ---- */
CREATE TABLE DiemThamQuan (
    MaDTQ    VARCHAR(10)    NOT NULL CONSTRAINT PK_DiemThamQuan PRIMARY KEY,
    TenDTQ   NVARCHAR(150)  NOT NULL,
    DiaDiem  NVARCHAR(150)  NOT NULL,
    NoiDung  NVARCHAR(1000) NULL,
    YNghia   NVARCHAR(1000) NULL
);

CREATE TABLE TourDiemThamQuan (
    MaTour  VARCHAR(10) NOT NULL CONSTRAINT FK_TDTQ_Tour REFERENCES Tour(MaTour) ON DELETE CASCADE,
    MaDTQ   VARCHAR(10) NOT NULL CONSTRAINT FK_TDTQ_DTQ  REFERENCES DiemThamQuan(MaDTQ),
    CONSTRAINT PK_TourDiemThamQuan PRIMARY KEY (MaTour, MaDTQ)
);

/* ---- ChuyenDi: Tour 1 --- 0..* ChuyenDi ---- */
CREATE TABLE ChuyenDi (
    MaChuyen   VARCHAR(10) NOT NULL CONSTRAINT PK_ChuyenDi PRIMARY KEY,
    MaTour     VARCHAR(10) NOT NULL CONSTRAINT FK_ChuyenDi_Tour REFERENCES Tour(MaTour),
    NgayDi     DATE        NOT NULL,
    NgayVe     DATE        NOT NULL,
    TrangThai  NVARCHAR(20) NOT NULL CONSTRAINT DF_CD_TT DEFAULT N'ChuaKhoiHanh',
    CONSTRAINT CK_CD_Ngay CHECK (NgayVe >= NgayDi),
    CONSTRAINT CK_CD_TT   CHECK (TrangThai IN (N'ChuaKhoiHanh', N'DangDi', N'HoanThanh', N'Huy')),
    CONSTRAINT UQ_CD_Tour_NgayDi UNIQUE (MaTour, NgayDi)   -- 1 tour không mở 2 chuyến cùng ngày đi
);

/* ---- DiemBanVe ---- */
CREATE TABLE DiemBanVe (
    MaDiemBan   VARCHAR(10)   NOT NULL CONSTRAINT PK_DiemBanVe PRIMARY KEY,
    TenDiemBan  NVARCHAR(100) NOT NULL,
    DiaChi      NVARCHAR(200) NOT NULL
);

/* ---- PhieuDangKyDoan: KhachDoan 1 --- 0..*, Tour 1 --- 0..* ---- */
CREATE TABLE PhieuDangKyDoan (
    MaPhieuDoan  VARCHAR(10)   NOT NULL CONSTRAINT PK_PhieuDangKyDoan PRIMARY KEY,
    MaKH         VARCHAR(10)   NOT NULL CONSTRAINT FK_PDKD_KhachDoan REFERENCES KhachDoan(MaKH),
    MaTour       VARCHAR(10)   NOT NULL CONSTRAINT FK_PDKD_Tour      REFERENCES Tour(MaTour),
    NgayLap      DATE          NOT NULL CONSTRAINT DF_PDKD_NgayLap DEFAULT CAST(GETDATE() AS DATE),
    NgayDi       DATE          NOT NULL,                       -- đoàn được chọn ngày đi bất kỳ
    SoNguoi      INT           NOT NULL CONSTRAINT CK_PDKD_SoNguoi CHECK (SoNguoi > 12),
    DiaDiemDon   NVARCHAR(200) NOT NULL,
    CoBaoHiem    BIT           NOT NULL CONSTRAINT DF_PDKD_BH DEFAULT 0,
    TienCoc      DECIMAL(15,0) NOT NULL CONSTRAINT CK_PDKD_Coc CHECK (TienCoc >= 0),
    TrangThai    NVARCHAR(20)  NOT NULL CONSTRAINT DF_PDKD_TT DEFAULT N'DaDatCoc',
    CONSTRAINT CK_PDKD_Ngay CHECK (NgayDi >= NgayLap),
    CONSTRAINT CK_PDKD_TT   CHECK (TrangThai IN (N'DaDatCoc', N'DaHuy', N'HoanThanh'))
);

/* ---- ThanhVienDoan: PhieuDangKyDoan 1 <>--- 0..* (composition -> xóa phiếu xóa luôn) ---- */
CREATE TABLE ThanhVienDoan (
    MaTV         VARCHAR(10)   NOT NULL CONSTRAINT PK_ThanhVienDoan PRIMARY KEY,
    MaPhieuDoan  VARCHAR(10)   NOT NULL
                 CONSTRAINT FK_TVD_Phieu REFERENCES PhieuDangKyDoan(MaPhieuDoan) ON DELETE CASCADE,
    HoTen        NVARCHAR(100) NOT NULL
);

/* ---- PhieuDangKyChuyen: KhachLe 1, ChuyenDi 1, DiemBanVe 1 --- 0..* ---- */
CREATE TABLE PhieuDangKyChuyen (
    MaVe        VARCHAR(10)   NOT NULL CONSTRAINT PK_PhieuDangKyChuyen PRIMARY KEY,
    MaKH        VARCHAR(10)   NOT NULL CONSTRAINT FK_PDKC_KhachLe  REFERENCES KhachLe(MaKH),
    MaChuyen    VARCHAR(10)   NOT NULL CONSTRAINT FK_PDKC_ChuyenDi REFERENCES ChuyenDi(MaChuyen),
    MaDiemBan   VARCHAR(10)   NOT NULL CONSTRAINT FK_PDKC_DiemBan  REFERENCES DiemBanVe(MaDiemBan),
    SoNguoi     INT           NOT NULL CONSTRAINT CK_PDKC_SoNguoi CHECK (SoNguoi BETWEEN 1 AND 12),
    NgayDat     DATETIME      NOT NULL CONSTRAINT DF_PDKC_NgayDat DEFAULT GETDATE(),
    TienVe      DECIMAL(15,0) NOT NULL CONSTRAINT CK_PDKC_TienVe CHECK (TienVe >= 0),
    TrangThaiTT NVARCHAR(20)  NOT NULL CONSTRAINT DF_PDKC_TT DEFAULT N'ChuaThanhToan',
    CONSTRAINT CK_PDKC_TT CHECK (TrangThaiTT IN (N'ChuaThanhToan', N'DaThanhToan', N'DaHuy'))
);

/* ---- PhanCong: NhanVien 1 --- 0..*; PhieuDangKyDoan 0..1 --- 0..*; ChuyenDi 0..1 --- 0..1
        Mỗi dòng phân công cho ĐÚNG MỘT trong hai: phiếu đoàn HOẶC chuyến (khách lẻ). ---- */
CREATE TABLE PhanCong (
    MaPC         VARCHAR(10)   NOT NULL CONSTRAINT PK_PhanCong PRIMARY KEY,
    MaNV         VARCHAR(10)   NOT NULL CONSTRAINT FK_PC_NhanVien REFERENCES NhanVien(MaNV),
    MaPhieuDoan  VARCHAR(10)   NULL CONSTRAINT FK_PC_PhieuDoan REFERENCES PhieuDangKyDoan(MaPhieuDoan),
    MaChuyen     VARCHAR(10)   NULL CONSTRAINT FK_PC_ChuyenDi  REFERENCES ChuyenDi(MaChuyen),
    NgayBatDau   DATE          NOT NULL,
    NgayKetThuc  DATE          NOT NULL,
    TienCongTour DECIMAL(15,0) NOT NULL CONSTRAINT CK_PC_Tien CHECK (TienCongTour >= 0),
    CONSTRAINT CK_PC_Ngay CHECK (NgayKetThuc >= NgayBatDau),
    CONSTRAINT CK_PC_XorDoiTuong CHECK (
        (MaPhieuDoan IS NOT NULL AND MaChuyen IS NULL) OR (MaPhieuDoan IS NULL AND MaChuyen IS NOT NULL)),
    -- không trùng cùng NV phân công 2 lần cho cùng 1 phiếu
    CONSTRAINT UQ_PC_NV_Phieu UNIQUE (MaNV, MaPhieuDoan)
);
-- Mỗi chuyến khách lẻ chỉ có MỘT nhân viên (NULL không bị tính trùng nhờ filtered index)
CREATE UNIQUE INDEX UQ_PC_MotNVMoiChuyen ON PhanCong (MaChuyen) WHERE MaChuyen IS NOT NULL;
CREATE INDEX IX_PC_NV_Ngay ON PhanCong (MaNV, NgayBatDau, NgayKetThuc);
GO

/* =====================================================================
   2. HÀM + TRIGGER
   ===================================================================== */

/* KiemTraChongCheo(): 1 = nhân viên đã có lịch trùng khoảng ngày này */
CREATE FUNCTION dbo.fn_KiemTraChongCheo
    (@MaNV VARCHAR(10), @BatDau DATE, @KetThuc DATE, @MaPCBoQua VARCHAR(10) = NULL)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (
        SELECT 1 FROM dbo.PhanCong
        WHERE MaNV = @MaNV
          AND (@MaPCBoQua IS NULL OR MaPC <> @MaPCBoQua)
          AND NgayBatDau  <= @KetThuc
          AND NgayKetThuc >= @BatDau) THEN 1 ELSE 0 END;
END;
GO

/* TinhLuongThang(): lương cơ bản + tiền công các tour kết thúc trong tháng */
CREATE FUNCTION dbo.fn_TinhLuongThang (@MaNV VARCHAR(10), @Thang INT, @Nam INT)
RETURNS DECIMAL(15,0)
AS
BEGIN
    DECLARE @Luong DECIMAL(15,0);
    SELECT @Luong = nv.LuongCoBan + ISNULL((
               SELECT SUM(pc.TienCongTour) FROM dbo.PhanCong pc
               WHERE pc.MaNV = nv.MaNV
                 AND MONTH(pc.NgayKetThuc) = @Thang AND YEAR(pc.NgayKetThuc) = @Nam), 0)
    FROM dbo.NhanVien nv WHERE nv.MaNV = @MaNV;
    RETURN @Luong;
END;
GO

/* TinhGiaTour(): giá tour theo số khách */
CREATE FUNCTION dbo.fn_TinhGiaTour (@MaTour VARCHAR(10), @SoKhach INT)
RETURNS DECIMAL(15,0)
AS
BEGIN
    RETURN (SELECT DonGia * @SoKhach FROM dbo.Tour WHERE MaTour = @MaTour);
END;
GO

/* CHỐNG CHỒNG LỊCH PHÂN CÔNG: một nhân viên không được có 2 khoảng ngày giao nhau */
CREATE TRIGGER trg_PhanCong_ChongChongLich
ON PhanCong
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN PhanCong p
          ON p.MaNV = i.MaNV
         AND p.MaPC <> i.MaPC
         AND i.NgayBatDau  <= p.NgayKetThuc
         AND i.NgayKetThuc >= p.NgayBatDau)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, N'Nhân viên đã có lịch phân công trùng thời gian (chồng chéo).', 1;
    END
END;
GO

/* =====================================================================
   3. DỮ LIỆU MẪU
   ===================================================================== */
INSERT INTO NhanVien (MaNV, HoTen, ChucVu, LuongCoBan) VALUES
('NV01', N'Nguyễn Hoàng Nam',   N'Hướng dẫn viên',  8000000),
('NV02', N'Trần Thị Mai',       N'Hướng dẫn viên',  8000000),
('NV03', N'Lê Văn Tài',         N'Hướng dẫn viên',  7500000),
('NV04', N'Phạm Thanh Hương',   N'Hướng dẫn viên',  7500000),
('NV05', N'Võ Thị Lan',         N'Nhân viên bán vé',7000000),
('NV06', N'Đặng Quang Huy',     N'Quản lý',        15000000);

INSERT INTO KhachHang (MaKH, LoaiKH, TenKH, DiaChi, DienThoai) VALUES
('KH001','DOAN', N'Công ty TNHH ABC',          N'12 Nguyễn Huệ, Q.1, TP.HCM',       '0901000001'),
('KH002','DOAN', N'Trường THPT Lê Quý Đôn',    N'110 Nguyễn Thị Minh Khai, Q.3',    '0901000002'),
('KH003','LE',   N'Lê Minh Châu',              N'25 Phan Văn Trị, Gò Vấp',          '0902000001'),
('KH004','LE',   N'Phạm Quốc Dũng',            N'8 Võ Văn Ngân, Thủ Đức',           '0902000002'),
('KH005','LE',   N'Hoàng Thu Hà',              N'77 Lê Lợi, Q.1',                   '0902000003');

INSERT INTO KhachDoan (MaKH, NguoiDaiDien, GhiChuCSKH) VALUES
('KH001', N'Nguyễn Văn An', N'Công ty đi team building hằng năm'),
('KH002', N'Trần Thị Bình', N'Đoàn học sinh, cần xe có máy lạnh');
INSERT INTO KhachLe (MaKH) VALUES ('KH003'), ('KH004'), ('KH005');

INSERT INTO PhieuKhaoSat (MaPK, MaKH, NgayGui, NoiDungGopY) VALUES
('PK001','KH001','2026-09-20 09:00', N'Hướng dẫn viên nhiệt tình, khách sạn hơi xa trung tâm.'),
('PK002','KH003','2026-09-25 10:30', NULL);

INSERT INTO PhuongTien (MaPT, TenPT) VALUES
('PT01', N'Máy bay'), ('PT02', N'Xe đò'), ('PT03', N'Tàu hỏa'), ('PT04', N'Tàu thủy');

INSERT INTO Tour (MaTour, TenTour, SoNgay, SoDem, DonGia) VALUES
('T01', N'Đà Nẵng - Hội An',        4, 3, 4500000),
('T02', N'Hà Nội - Hạ Long - Sa Pa',6, 5, 6200000),
('T03', N'Phú Quốc nghỉ dưỡng',     3, 2, 7800000);

INSERT INTO DiemDung (MaDiemDung, MaTour, MaPT, ThuTu, NoiDen, DoiPhuongTien, CoAn, CoKhachSan, LoaiKhachSan) VALUES
('DD01','T01','PT01',1,N'Đà Nẵng', 0,1,1,4),
('DD02','T01','PT02',2,N'Hội An',  1,1,1,3),
('DD03','T01','PT01',3,N'TP.HCM',  1,0,0,NULL),
('DD04','T02','PT01',1,N'Hà Nội',  0,1,1,4),
('DD05','T02','PT02',2,N'Hạ Long', 1,1,1,5),
('DD06','T02','PT03',3,N'Sa Pa',   1,1,1,3),
('DD07','T02','PT01',4,N'TP.HCM',  1,0,0,NULL),
('DD08','T03','PT01',1,N'Phú Quốc',0,1,1,4),
('DD09','T03','PT01',2,N'TP.HCM',  1,0,0,NULL);

INSERT INTO DiemThamQuan (MaDTQ, TenDTQ, DiaDiem, NoiDung, YNghia) VALUES
('DTQ01', N'Bà Nà Hills',         N'Đà Nẵng',  N'Cáp treo, Cầu Vàng, làng Pháp',      N'Danh lam thắng cảnh nổi tiếng miền Trung'),
('DTQ02', N'Phố cổ Hội An',       N'Quảng Nam',N'Chùa Cầu, nhà cổ, đèn lồng',          N'Di sản văn hóa thế giới UNESCO'),
('DTQ03', N'Vịnh Hạ Long',        N'Quảng Ninh',N'Du thuyền, hang Sửng Sốt',           N'Di sản thiên nhiên thế giới UNESCO'),
('DTQ04', N'Hoàng thành Thăng Long',N'Hà Nội', N'Điện Kính Thiên, Đoan Môn',           N'Di tích lịch sử hơn 1000 năm'),
('DTQ05', N'Bãi Sao',             N'Phú Quốc', N'Tắm biển, bãi cát trắng',             N'Bãi biển đẹp bậc nhất đảo ngọc');

INSERT INTO TourDiemThamQuan (MaTour, MaDTQ) VALUES
('T01','DTQ01'), ('T01','DTQ02'), ('T02','DTQ03'), ('T02','DTQ04'), ('T03','DTQ05');

INSERT INTO ChuyenDi (MaChuyen, MaTour, NgayDi, NgayVe, TrangThai) VALUES
('CD01','T02','2026-11-20','2026-11-25', N'ChuaKhoiHanh'),
('CD02','T01','2026-11-05','2026-11-08', N'ChuaKhoiHanh'),
('CD03','T03','2026-12-01','2026-12-03', N'ChuaKhoiHanh'),
('CD04','T01','2026-12-10','2026-12-13', N'ChuaKhoiHanh');   -- chưa phân công HDV

INSERT INTO DiemBanVe (MaDiemBan, TenDiemBan, DiaChi) VALUES
('DB01', N'Điểm bán vé Quận 1',  N'45 Lê Lợi, Q.1, TP.HCM'),
('DB02', N'Điểm bán vé Thủ Đức', N'120 Võ Văn Ngân, TP. Thủ Đức'),
('DB03', N'Điểm bán vé Gò Vấp',  N'300 Quang Trung, Gò Vấp');

INSERT INTO PhieuDangKyDoan (MaPhieuDoan, MaKH, MaTour, NgayLap, NgayDi, SoNguoi, DiaDiemDon, CoBaoHiem, TienCoc, TrangThai) VALUES
('PD01','KH001','T01','2026-10-01','2026-11-10',20, N'12 Nguyễn Huệ, Q.1, TP.HCM',          1, 20000000, N'DaDatCoc'),
('PD02','KH002','T03','2026-10-05','2026-12-15',15, N'110 Nguyễn Thị Minh Khai, Q.3',       0, 15000000, N'DaDatCoc');

-- Có mua bảo hiểm -> phải có danh sách thành viên (mẫu 5 người của PD01)
INSERT INTO ThanhVienDoan (MaTV, MaPhieuDoan, HoTen) VALUES
('TV001','PD01',N'Nguyễn Văn An'), ('TV002','PD01',N'Trần Văn Bảo'),
('TV003','PD01',N'Lê Thị Cúc'),    ('TV004','PD01',N'Phạm Văn Đức'),
('TV005','PD01',N'Hoàng Thị Em');

INSERT INTO PhieuDangKyChuyen (MaVe, MaKH, MaChuyen, MaDiemBan, SoNguoi, NgayDat, TienVe, TrangThaiTT) VALUES
('PV001','KH003','CD01','DB01',2,'2026-10-02 14:00', 12400000, N'DaThanhToan'),   -- 2 x 6.200.000
('PV002','KH004','CD02','DB02',1,'2026-10-03 09:15',  4500000, N'DaThanhToan'),   -- 1 x 4.500.000
('PV003','KH005','CD03','DB01',4,'2026-10-04 16:40', 31200000, N'ChuaThanhToan'); -- 4 x 7.800.000

-- Phân công (nhiều dòng 1 lệnh: trigger kiểm tra toàn bộ, không chồng lịch)
INSERT INTO PhanCong (MaPC, MaNV, MaPhieuDoan, MaChuyen, NgayBatDau, NgayKetThuc, TienCongTour) VALUES
('PC01','NV01','PD01',NULL,  '2026-11-10','2026-11-13', 1500000),  -- đoàn đông: 2 HDV
('PC02','NV02','PD01',NULL,  '2026-11-10','2026-11-13', 1500000),
('PC03','NV01',NULL,'CD01',  '2026-11-20','2026-11-25', 2500000),
('PC04','NV03',NULL,'CD02',  '2026-11-05','2026-11-08', 1500000),
('PC05','NV02',NULL,'CD03',  '2026-12-01','2026-12-03', 1200000),
('PC06','NV04','PD02',NULL,  '2026-12-15','2026-12-17', 1200000);
GO

/* =====================================================================
   4. TRUY VẤN KIỂM TRA / TEST RÀNG BUỘC
   ===================================================================== */
-- Lương tháng 11/2026
SELECT MaNV, HoTen, dbo.fn_TinhLuongThang(MaNV, 11, 2026) AS Luong_T11_2026 FROM NhanVien;

-- Giá tour cho 3 khách
SELECT dbo.fn_TinhGiaTour('T01', 3) AS GiaTour;

-- Có chồng lịch không? (NV01 từ 12/11 đến 14/11 -> trùng PC01 => 1)
SELECT dbo.fn_KiemTraChongCheo('NV01','2026-11-12','2026-11-14', NULL) AS ChongCheo;

-- Danh sách khách kèm loại
SELECT kh.MaKH, kh.TenKH, kh.LoaiKH, kd.NguoiDaiDien FROM KhachHang kh LEFT JOIN KhachDoan kd ON kd.MaKH = kh.MaKH;

/* ---- Các lệnh dưới đây PHẢI BÁO LỖI (bỏ comment để thử) ----
-- (a) Trùng lịch: NV02 đã có PC05 (01-03/12)
-- INSERT INTO PhanCong VALUES ('PC99','NV02',NULL,'CD04','2026-12-02','2026-12-04',1000000);
-- (b) Khách đoàn chỉ 10 người (vi phạm CHECK SoNguoi > 12)
-- INSERT INTO PhieuDangKyDoan (MaPhieuDoan,MaKH,MaTour,NgayLap,NgayDi,SoNguoi,DiaDiemDon,TienCoc)
--        VALUES ('PD99','KH001','T01','2026-10-09','2026-11-30',10,N'abc',0);
-- (c) Ngày về trước ngày đi
-- INSERT INTO ChuyenDi VALUES ('CD99','T01','2026-12-20','2026-12-18',N'ChuaKhoiHanh');
-- (d) Vé khách lẻ 20 người (vi phạm CHECK <= 12)
-- INSERT INTO PhieuDangKyChuyen (MaVe,MaKH,MaChuyen,MaDiemBan,SoNguoi,TienVe)
--        VALUES ('PV99','KH003','CD04','DB01',20,1);
-- (e) 1 chuyến khách lẻ có 2 HDV (vi phạm UNIQUE index)
-- INSERT INTO PhanCong VALUES ('PC98','NV04',NULL,'CD02','2026-11-05','2026-11-08',1);
-- (f) Dùng mã khách đoàn làm khách lẻ (FK ghép LoaiKH chặn)
-- INSERT INTO KhachLe (MaKH) VALUES ('KH001');
*/
