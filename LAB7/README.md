# Quản lý nhân sự – Phân hệ Khen thưởng (Công ty sơn Đông Á)

Ứng dụng Windows Forms (C#) kết nối SQL Server, hiện thực nghiệp vụ **"Lập quyết định khen thưởng"** cho cá nhân hoặc tập thể phòng ban, có bước **Giám đốc ký duyệt** và **lập phiếu chi khen thưởng**.

Đây là bài thực hành môn *Thực hành Phân tích thiết kế hướng đối tượng* (Bài 7 – Quản lý nhân sự): các sơ đồ UML được vẽ ở các câu trước, phần này chuyển sơ đồ Sequence thành code chạy được.

## Chức năng

| Form | Mô tả |
|---|---|
| **FormLapQuyetDinh** | Nhân viên nhân sự chọn đối tượng (cá nhân / tập thể phòng ban), chọn loại thưởng, nhập nội dung, số tiền, ngày quyết định rồi lưu. Quyết định mới có trạng thái `ChoDuyet`. Bảng bên dưới hiển thị các quyết định gần đây. |
| **FormKyDuyet** | Giám đốc xem danh sách quyết định đang chờ duyệt. **Duyệt**: cập nhật trạng thái `DaDuyet` và tạo phiếu chi trong cùng một transaction. **Từ chối**: cập nhật trạng thái `TuChoi`. |

### Quy tắc nghiệp vụ
- Mỗi quyết định khen thưởng tương ứng **đúng một** phiếu chi khen thưởng (ràng buộc `UNIQUE` trên `PhieuChiKhenThuong.maQD`).
- Lương tháng 13, thưởng lễ, thưởng cuối năm, thưởng thành tích đều đi qua quyết định khen thưởng và do Giám đốc ký duyệt.
- Khen thưởng cá nhân thì gắn với một nhân viên, khen thưởng tập thể thì gắn với một phòng ban (ràng buộc `CHECK` trong CSDL).
- Duyệt và tạo phiếu chi chạy trong **một transaction**: lỗi ở bước nào thì hoàn tác (rollback) toàn bộ.

## Công nghệ

- C# – Windows Forms (.NET Framework)
- SQL Server + SQL Server Management Studio (SSMS)
- ADO.NET (`System.Data.SqlClient`), truy vấn có tham số (parameterized query)
- Visual Studio

## Cấu trúc CSDL `QuanLyNhanSu_DongA`

| Bảng | Cột chính |
|---|---|
| `PhongBan` | `maPB` (PK), `tenPB` |
| `NhanVien` | `maNV` (PK), `hoTen`, `maPB` (FK), `chucVu` |
| `QuyetDinhKhenThuong` | `maQD` (PK), `loaiDoiTuong` (`CaNhan` / `TapThe`), `maNV` (FK), `maPB` (FK), `loaiThuong`, `noiDung`, `soTien`, `ngayQD`, `trangThai` (`ChoDuyet` / `DaDuyet` / `TuChoi`) |
| `PhieuChiKhenThuong` | `maPC` (PK), `maQD` (FK, UNIQUE), `soTien`, `ngayChi` |

## Cấu trúc thư mục

```
.
├── README.md
├── database/
│   └── QuanLyNhanSu_DongA.sql      # Script tạo CSDL + dữ liệu mẫu
├── docs/
│   └── sequence-khen-thuong.png    # Sequence Diagram: Lập quyết định khen thưởng
└── WindowsFormsApp1/
    ├── Db.cs                       # Chuỗi kết nối CSDL
    ├── FormLapQuyetDinh.cs         # Form lập quyết định khen thưởng
    ├── FormKyDuyet.cs              # Form Giám đốc ký duyệt
    └── Program.cs                  # Điểm khởi chạy
```

## Cài đặt và chạy

**Yêu cầu:** Windows, Visual Studio (có workload *.NET desktop development*), SQL Server và SSMS.

1. **Tạo CSDL:** mở SSMS, mở file `database/QuanLyNhanSu_DongA.sql` rồi bấm **Execute** (F5). Script sẽ tạo CSDL, các bảng và dữ liệu mẫu.
2. **Mở project:** mở thư mục `WindowsFormsApp1` bằng Visual Studio (file `.sln`).
3. **Sửa chuỗi kết nối** trong `Db.cs` cho đúng tên server của máy bạn (xem ô *Server name* khi mở SSMS):

   ```csharp
   public const string ConnStr =
       "Server=localhost;Database=QuanLyNhanSu_DongA;Integrated Security=True;TrustServerCertificate=True;";
   ```

   Ví dụ khác: `Server=.\SQLEXPRESS;...` hoặc `Server=(localdb)\MSSQLLocalDB;...`
4. Nhấn **F5** để chạy. Form lập quyết định mở đầu tiên; bấm **Mở form ký duyệt** để sang form của Giám đốc.

> Nếu tạo project bằng template ".NET" (không phải .NET Framework) và báo thiếu `SqlClient`, cài thêm gói NuGet `System.Data.SqlClient`.

## Hướng dẫn thử nhanh

1. Ở form lập quyết định, chọn **Cá nhân** → chọn `NV002` → loại thưởng "Thưởng lễ" → nhập nội dung và số tiền `2000000` → **Lưu quyết định**. Bảng bên dưới sẽ có thêm `QD004` trạng thái `ChoDuyet`.
2. Bấm **Mở form ký duyệt**, chọn một quyết định → **Duyệt**. Hệ thống tạo phiếu chi mới (ví dụ `PC002`).
3. Kiểm tra trong SSMS:

   ```sql
   SELECT * FROM QuyetDinhKhenThuong;
   SELECT * FROM PhieuChiKhenThuong;
   ```

Muốn đưa dữ liệu về trạng thái ban đầu, chạy lại script `QuanLyNhanSu_DongA.sql`.

## Sơ đồ

Sequence Diagram nghiệp vụ "Lập quyết định khen thưởng" (3 giai đoạn: *Chọn đối tượng*, *Lập quyết định*, *Ký duyệt và lưu*):

![Sequence Diagram](docs/sequence-khen-thuong.png)

## Hướng phát triển

- Thêm form danh sách và lọc quyết định / phiếu chi theo loại thưởng, trạng thái.
- Lưu lý do từ chối quyết định.
- Thêm đăng nhập và phân quyền (Nhân viên nhân sự / Giám đốc).

## Tác giả

- **Nhan Anh Thư** – Sinh viên ngành Công nghệ phần mềm, Khoa Công nghệ thông tin, Trường Đại học Tài nguyên và Môi trường TP.HCM (lớp 12_ĐH_CNPM2, khóa 2023–2027)

*Sản phẩm phục vụ mục đích học tập.*
