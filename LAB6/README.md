<div align="center">

# 🏥 Quản lý Hồ sơ Bệnh án của Bệnh nhân

**Lab 6 · Phân tích thiết kế hướng đối tượng**
Đại học Công nghệ TP.HCM (HUTECH)

![UML](https://img.shields.io/badge/UML-StarUML%20%7C%20draw.io-blue)
![PlantUML](https://img.shields.io/badge/Diagram-PlantUML-orange)
![SQL Server](https://img.shields.io/badge/Database-SQL%20Server-red)
![WinForms](https://img.shields.io/badge/UI-WinForms-purple)

</div>

---

## 📌 Giới thiệu

Đồ án phân tích và thiết kế phần mềm quản lý bệnh án cho một **bệnh viện đa khoa quốc tế**. Hệ thống hỗ trợ:

- Đăng ký khám lần đầu, đóng lệ phí năm và cấp hồ sơ bệnh án
- Lập phiếu khám, ghi nhận triệu chứng, chỉ định xét nghiệm
- Lập toa thuốc, thanh toán viện phí và hoàn tất đợt điều trị
- Tra cứu lịch sử bệnh án
- Đặt lịch khám sức khỏe định kỳ theo quý (miễn phí)

## 👤 Thông tin sinh viên

| | |
|---|---|
| **Họ và tên** | [Họ tên] |
| **MSSV** | [MSSV] |
| **Lớp** | [Lớp] |
| **Nhóm TH** | [Nhóm] |
| **Giảng viên** | Huỳnh Phạm Trọng |

## 🎯 Mục tiêu

- [x] Xác định Class, thuộc tính, phương thức, ID
- [x] Vẽ Class Diagram (association, multiplicity)
- [x] Vẽ Use Case tổng quát
- [x] Vẽ Use Case phân rã (đăng ký khám → xét nghiệm → nhận toa)
- [x] Vẽ Activity Diagram
- [x] Vẽ Sequence Diagram nghiệp vụ "Lập toa thuốc"
- [ ] Thiết kế CSDL SQL Server (PK, FK, UNIQUE, transaction)
- [ ] Xây dựng ứng dụng WinForms theo module
- [ ] Kiểm thử các quy tắc nghiệp vụ

## 📁 Cấu trúc thư mục

```
.
├── README.md
├── docs/
│   ├── Bai_5_Quan_ly_ho_so_benh_an.pdf     # Đề bài
│   └── BaiLam.docx                         # Bài làm 6 câu
├── diagrams/
│   ├── class_diagram.drawio
│   ├── erd.drawio
│   ├── usecase_tong_quat.drawio
│   ├── usecase_phan_ra.drawio
│   ├── activity.drawio
│   ├── sequence_lap_toa_thuoc.puml
│   └── images/                             # Ảnh PNG xuất từ các sơ đồ
├── database/
│   └── script.sql
└── src/
    └── QuanLyBenhAn/                       # Project WinForms
```

## 🧩 Danh sách Class

| # | Class | ID | Mô tả |
|---|---|---|---|
| 1 | `BenhNhan` | maBN | Thông tin trên phiếu đăng ký |
| 2 | `LePhiNam` | maLePhi | Lệ phí quản lý và khám định kỳ hằng năm |
| 3 | `HoSoBenhAn` | maHoSo | Hồ sơ cấp cho bệnh nhân, mã in trên trang bìa |
| 4 | `PhieuKham` | maPK | Mỗi lần khám (điều trị hoặc định kỳ) |
| 5 | `BacSi` | maBS | Bác sĩ khám và kê toa |
| 6 | `Khoa` | maKhoa | Khoa điều trị |
| 7 | `NhanVienCSKH` | maNV | Nhân viên phòng chăm sóc khách hàng |
| 8 | `LichKhamDinhKy` | maLich | Lịch hẹn khám định kỳ theo quý |
| 9 | `XetNghiem` | maXN | Danh mục xét nghiệm |
| 10 | `ChiDinhXN` | maChiDinh | Chỉ định và kết quả xét nghiệm của phiếu khám |
| 11 | `ToaThuoc` | maToa | Toa thuốc của phiếu khám |
| 12 | `ChiTietToa` | maCT | Từng dòng thuốc trong toa |
| 13 | `Thuoc` | maThuoc | Danh mục thuốc |
| 14 | `HoaDon` | maHD | Viện phí của phiếu khám |

## 🔗 Quan hệ chính

| Quan hệ | Bản số |
|---|---|
| BenhNhan – LePhiNam | 1 – 0..* |
| BenhNhan – HoSoBenhAn | 1 – 1 |
| BenhNhan – LichKhamDinhKy | 1 – 0..* |
| HoSoBenhAn – PhieuKham | 1 – 0..* (composition) |
| BacSi – PhieuKham | 1 – 0..* |
| Khoa – PhieuKham / Khoa – BacSi | 1 – 0..* / 1 – 1..* |
| PhieuKham – ChiDinhXN – XetNghiem | 1 – 0..* / 1 – 0..* |
| PhieuKham – ToaThuoc | 1 – 0..1 |
| ToaThuoc – ChiTietToa (composition) | 1 – 1..* |
| Thuoc – ChiTietToa | 1 – 0..* |
| PhieuKham – HoaDon | 1 – 0..1 |

## 👥 Actor và Use Case

**Actor:** Bệnh nhân · NV CSKH / Lễ tân · Bác sĩ · NV Xét nghiệm · Thu ngân · Quản trị viên

**Use Case chính:** Đăng ký khám lần đầu · Đóng lệ phí năm · Cấp hồ sơ · Tra cứu hồ sơ · Lập phiếu khám · Chỉ định xét nghiệm · Nhập kết quả xét nghiệm · Lập toa thuốc · Thanh toán viện phí · Hoàn tất đợt điều trị · Đặt lịch khám định kỳ · Quản lý danh mục

## 📐 Sơ đồ

| Sơ đồ | Công cụ | Xem |
|---|---|---|
| Class Diagram | draw.io | `diagrams/images/class.png` |
| ERD | draw.io | `diagrams/images/erd.png` |
| Use Case tổng quát | draw.io | `diagrams/images/usecase_tong_quat.png` |
| Use Case phân rã | draw.io | `diagrams/images/usecase_phan_ra.png` |
| Activity Diagram | draw.io | `diagrams/images/activity.png` |
| Sequence "Lập toa thuốc" | PlantUML | `diagrams/images/sequence.png` |

> Thêm ảnh trực tiếp vào README bằng cú pháp `![Class Diagram](diagrams/images/class.png)`.

## 📜 Quy tắc nghiệp vụ cần kiểm thử

1. Đăng ký lần đầu phải **đóng lệ phí năm** thì mới được **cấp hồ sơ**.
2. Mỗi bệnh nhân chỉ có **một hồ sơ**, mỗi năm chỉ đóng **một lệ phí**.
3. Hồ sơ hết hạn thì phải đóng lệ phí năm mới.
4. Tra cứu được lịch sử khám bằng mã hồ sơ hoặc thông tin tìm kiếm khác.
5. Mỗi bệnh nhân được **khám định kỳ miễn phí 1 lần mỗi quý**.
6. Xét nghiệm và toa thuốc phải **liên kết với phiếu khám**.
7. Chỉ **hoàn tất đợt điều trị** sau khi đã **thanh toán viện phí**.
8. Các nghiệp vụ nhiều bảng (đăng ký lần đầu, lập toa) dùng **transaction**.

## 🛠️ Công nghệ

| Thành phần | Công nghệ |
|---|---|
| Mô hình UML | StarUML, draw.io, PlantUML |
| Cơ sở dữ liệu | SQL Server |
| Giao diện | C# WinForms (.NET) |
| Quản lý mã nguồn | Git, GitHub |

## ▶️ Cách xem sơ đồ

- File `.drawio`: mở bằng [app.diagrams.net](https://app.diagrams.net) hoặc extension **Draw.io Integration** của VS Code.
- File `.puml`: dán vào [plantuml.com/plantuml](https://www.plantuml.com/plantuml) hoặc dùng extension **PlantUML** của VS Code.

## 🗄️ Cách chạy (sẽ cập nhật)

```bash
# 1. Tạo CSDL
sqlcmd -S . -i database/script.sql

# 2. Mở solution bằng Visual Studio
src/QuanLyBenhAn/QuanLyBenhAn.sln

# 3. Sửa chuỗi kết nối trong App.config rồi bấm F5
```

## 📚 Tài liệu tham khảo

- Đề bài: *Bài 5 – Quản lý hồ sơ bệnh án của bệnh nhân*, HUTECH
- [UML Diagrams](https://www.uml-diagrams.org/)
- [PlantUML Documentation](https://plantuml.com/)

---

<div align="center">

Made with ☕ by **[Họ tên]** · HUTECH · HK1 2026-2027

</div>
