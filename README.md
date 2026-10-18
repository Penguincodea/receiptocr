# Receipt OCR & Expense Tracker

Ứng dụng di động quản lý chi tiêu cá nhân thông minh kết hợp nhận dạng ký tự quang học (OCR) trên thiết bị Android, được phát triển bằng **Flutter & Dart**.

---

## 1. Giới thiệu dự án

**Receipt OCR & Expense Tracker** giúp người dùng ghi chép chi tiêu nhanh chóng bằng cách quét hóa đơn thông qua camera hoặc chọn ảnh hóa đơn sẵn có. Ứng dụng tự động bóc tách các trường thông tin quan trọng như **tên cửa hàng**, **tổng tiền (VND)** và **ngày giao dịch**, hiển thị màn hình kiểm tra (Review) và lưu trữ cục bộ an toàn qua SQLite.

### Tính năng nổi bật
* **Quét hóa đơn thông minh (On-Device OCR):** Sử dụng Google ML Kit Text Recognition chạy trực tiếp trên thiết bị (Offline 100%), bảo vệ quyền riêng tư, không gửi ảnh lên máy chủ.
* **Bộ bóc tách hóa đơn tiếng Việt (`ReceiptParser`):** Nhận diện đa dạng định dạng tiền tệ Việt Nam (`150,000 VND`, `150.000 đ`, `1.250.000 VNĐ`, `Tổng tiền: 150000`, `Thanh toán: 150.000`), ưu tiên từ khóa tổng thanh toán và loại bỏ các dòng tiền thối, chiết khấu.
* **Màn hình Review trước khi lưu:** Cho phép người dùng xem lại ảnh gốc, điều chỉnh tên đơn vị, số tiền, ngày tháng, danh mục chi tiêu và thêm ghi chú.
* **Lưu trữ SQLite cục bộ:** Bảng `expenses` bảo toàn dữ liệu và đường dẫn ảnh hóa đơn sau khi tắt/mở ứng dụng. Hỗ trợ thêm, sửa, xóa giao dịch.
* **Dashboard trực quan:** Thống kê tổng chi tiêu tháng hiện tại, danh sách giao dịch gần đây, trạng thái trống thân thiện.
* **Biểu đồ thuần `CustomPainter` (Không dùng thư viện bên thứ 3):**
  * **Animated Donut Chart:** Biểu đồ tròn thể hiện tỷ lệ % cơ cấu danh mục kèm hoạt ảnh mượt mà và chú giải.
  * **Weekly Spending Bar Chart:** Biểu đồ cột thể hiện chi tiêu 7 ngày qua, nhãn ngày, trục tỷ lệ và hiển thị số tiền trực quan.

---

## 2. Công nghệ sử dụng

* **Framework:** Flutter 3.47+ / Dart 3.13+ (Hỗ trợ Material 3).
* **OCR:** `google_mlkit_text_recognition: ^0.17.1` (Nhận diện chữ Latinh & số trực tiếp trên máy).
* **Camera:** `camera: ^0.12.1` & `image_picker: ^1.2.4` (Hỗ trợ live preview, flash, lấy nét và fallback từ thư viện).
* **Cơ sở dữ liệu:** `sqflite: ^2.4.4+1` (Lưu trữ SQLite quan hệ).
* **Quản lý file:** `path_provider: ^2.1.6` & `path: ^1.9.1` (Lưu ảnh hóa đơn vào Document Directory).
* **Quản lý trạng thái:** `flutter_riverpod: ^3.4.3` (`Notifier` & `NotifierProvider`).
* **Định dạng:** `intl: ^0.20.3` (Định dạng tiền tệ `vi_VN` - `150.000 ₫` và ngày tháng).

---

## 3. Danh mục chi tiêu chuẩn

| Mã danh mục | Tên hiển thị | Màu sắc | Biểu tượng |
| :--- | :--- | :--- | :--- |
| `food` | Ăn uống | Đỏ `#EF4444` | `Icons.restaurant` |
| `study` | Học tập | Xanh dương `#3B82F6` | `Icons.school` |
| `travel` | Di chuyển | Xanh ngọc `#10B981` | `Icons.directions_car` |
| `gear` | Đồ dùng/Thiết bị | Vàng cam `#F59E0B` | `Icons.devices` |
| `entertainment` | Giải trí | Tím `#8B5CF6` | `Icons.sports_esports` |

---

## 4. Hướng dẫn cài đặt và chạy ứng dụng

### Yêu cầu môi trường
* Flutter SDK (3.24+ hoặc 3.47+)
* Android SDK (API 21 trở lên)
* Java JDK (17+)

### Cài đặt dependencies
```bash
flutter pub get
```

### Chạy kiểm thử tự động
```bash
flutter test
```

### Kiểm tra tĩnh (Static Analysis)
```bash
flutter analyze
```

### Chạy ứng dụng trên máy thật hoặc giả lập Android
```bash
flutter run
```

---

## 5. Lệnh build file APK Release

Để đóng gói bản phát hành độc lập:
```bash
flutter build apk --release
```

Tệp APK sau khi build sẽ được lưu tại:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. Cấu trúc mã nguồn

```text
lib/
├── main.dart                          # Khởi tạo App, ProviderScope, Theme Material 3
├── models/
│   └── expense_item.dart              # Model ExpenseItem & Enum ExpenseCategory
├── services/
│   ├── database_service.dart          # Quản lý SQLite Database & lưu ảnh nội bộ
│   ├── receipt_ocr_service.dart       # Tích hợp Google ML Kit Text Recognition
│   └── receipt_parser.dart            # Thuật toán trích xuất tên, tiền VND, ngày tháng
├── state/
│   └── expense_provider.dart          # Riverpod StateNotifier quản lý danh sách & thống kê
├── screens/
│   ├── dashboard_screen.dart          # Màn hình chính: Tổng chi, tác vụ nhanh, lịch sử
│   ├── receipt_scanner_screen.dart    # Camera preview, chụp ảnh, flash, OCR
│   ├── review_screen.dart             # Form xác nhận, chỉnh sửa thông tin giao dịch
│   └── analytics_screen.dart          # Màn hình báo cáo phân tích với 2 biểu đồ
└── widgets/
    ├── animated_donut_chart.dart      # Biểu đồ Donut vẽ bằng CustomPainter (canvas.drawArc)
    └── weekly_spending_chart.dart     # Biểu đồ cột 7 ngày vẽ bằng CustomPainter
```

---

