# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: Receipt OCR & Expense Tracker (On-Device OCR & Data Visualization)  
**Team / Student Name:** [Team Name or Student Name]  
**Submission Date:** [18/10/2026]  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. [Vi Trung Việt] — Student ID: [23IT.B245]
* **🔗 Live Demo URL:** [[APK Release] (https://drive.google.com/file/d/1sfpnWhtm89HG4TifXWrog-NBkE8tMSEh/view?usp=drive_link)]
* **💻 GitHub Repository:** [https://github.com/username/your-repo-name]
* **🎥 Video Demo (Optional):** [https://youtu.be/xxx]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **On-Device OCR Receipt Scanning (100% Offline)** | ✅ Complete | Integrated `google_mlkit_text_recognition` running completely on-device with zero latency, offline capability, and high privacy without sending images to any third-party servers. |
| 2 | **Smart Vietnamese Receipt Parsing (`ReceiptParser`)** | ✅ Complete | Multi-pattern regex algorithm extracting total amount in VND (`150,000 VND`, `150.000 đ`, `1.250.000 VNĐ`), transaction date (`dd/MM/yyyy`, `yyyy-MM-dd`), and merchant name; filtering out discount, cash given, and change-return false positives. |
| 3 | **Interactive Review & Verification Screen** | ✅ Complete | Form for editing extracted fields, category selector (5 standard categories), notes, full-screen receipt photo inspector, and Vietnamese `DatePickerDialog` with safe range bounds (`2000`–`2100`). |
| 4 | **Local SQLite Persistence & Image Storage** | ✅ Complete | Relational SQLite storage via `sqflite` with full CRUD operations. Receipt photos are safely preserved by copying into the application's document directory (`path_provider`). |
| 5 | **Reactive State Management with Riverpod** | ✅ Complete | Implemented `flutter_riverpod` (`Notifier` & `NotifierProvider`), providing instant reactive updates across dashboard summary cards, recent transaction list, and analytics charts. |
| 6 | **Animated Donut Chart (`CustomPainter`)** | ✅ Complete | 100% pure Canvas-based animated category breakdown with 1000ms cubic easing curve (`CurvedAnimation`), percentage badges, legend chips, and central VND total. Zero third-party chart libraries used. |
| 7 | **Weekly Spending Bar Chart (`CustomPainter`)** | ✅ Complete | Native Canvas 7-day spending chart with linear gradient rounded bars, X-axis date labels, Y-axis horizontal grid lines, compact currency labels, and empty-state watermark. |
| 8 | **Automated Testing & Static Analysis** | ✅ Complete | Comprehensive test suite (`flutter test`) verifying parser algorithms and widget interactions with 100% pass rate. `flutter analyze` reports 0 issues (clean code quality). |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1. Directory Structure
```text
lib/
├── main.dart                          # App entry point, ProviderScope, ThemeData (Material 3), Vietnamese Localizations
├── models/
│   └── expense_item.dart              # ExpenseItem model, JSON/Map serialization, ExpenseCategory enum & metadata
├── services/
│   ├── database_service.dart          # SQLite singleton (sqflite), CRUD operations, internal image file preservation
│   ├── receipt_ocr_service.dart       # Google ML Kit Text Recognition integration & camera image processing
│   └── receipt_parser.dart            # Rule-based regex extraction engine for merchant, amount (VND), and date
├── state/
│   └── expense_provider.dart          # Riverpod ExpenseNotifier & ExpenseState (reactive totals & category sums)
├── screens/
│   ├── dashboard_screen.dart          # Main dashboard, monthly total hero card, recent transaction feed, manual entry
│   ├── receipt_scanner_screen.dart    # Live camera preview with framing overlay, flash control, and gallery fallback
│   ├── review_screen.dart             # Verification screen with image modal, Vietnamese date picker, form validation
│   └── analytics_screen.dart          # Metric summary cards, AnimatedDonutChart, and WeeklySpendingChart
└── widgets/
    ├── animated_donut_chart.dart      # Pure CustomPainter donut chart with smooth entry animation & legend
    └── weekly_spending_chart.dart     # Pure CustomPainter 7-day bar chart with coordinate grids & date labels
```

### 3.2. State Management Architecture
* **Unidirectional Data Flow:** UI components trigger actions on `ExpenseNotifier` via Riverpod (`ref.read(expenseProvider.notifier)`).
* The notifier communicates with `DatabaseService` to persist data in SQLite, queries updated records, recalculates derived values (current month total, 7-day spending series, category percentage distribution), and emits a new immutable `ExpenseState`.
* Subscribed UI widgets (`ref.watch(expenseProvider)`) rebuild efficiently without unnecessary full-tree rerenders.

### 3.3. Exception Handling & Robustness Strategies
* **Camera Hardware Fallback:** If camera initialization fails or permissions are denied, users are smoothly redirected to `image_picker` to select receipts from gallery.
* **OCR Ambiguity Guard:** `ReceiptParser` returns `null` for unidentifiable fields rather than hallucinating dummy data, allowing users to verify and complete fields on the review screen.
* **Safe Date Range & Localization Fallback:** `DatePickerDialog` clamps initial dates between `2000` and `2100` and wraps locale resolution in a try-catch block with default fallback, avoiding assertion and localization crashes.
* **Chart Empty-State Tolerance:** Both `CustomPainter` widgets detect when total spending is zero and render graceful placeholder watermarks and empty-ring visuals without throwing division-by-zero errors.

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

### 4.1. Application Flow & Key Interfaces
| Screen | Description | Screenshot Placeholder |
|---|---|:---:|
| **Dashboard Screen** | Displays current month spending hero card, quick actions ("Quét hóa đơn", "Nhập thủ công"), and chronologically ordered recent transactions. | `![Dashboard](screenshots/01_dashboard.png)` |
| **Receipt Scanner (OCR)** | Live camera viewfinder with a receipt bounding frame guide, flashlight toggle, and image picker button. | `![Scanner](screenshots/02_scanner.png)` |
| **Review & Verification** | Extracted merchant name, VND amount, Vietnamese transaction date picker, category selection, and original receipt thumbnail. | `![Review](screenshots/03_review.png)` |
| **Analytics & Custom Charts** | Animated Donut Chart representing category spending ratios alongside the 7-day Weekly Spending Bar Chart. | `![Analytics](screenshots/04_analytics.png)` |

*(Note: Place your emulator/device screenshots in a `screenshots/` folder or insert your image URLs into the placeholders above).*

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Challenge 1: Accurate On-Device Extraction of Vietnamese Receipt Formats
* **Problem:** Vietnamese receipts lack a standardized print format. Amounts appear with either periods or commas (`150.000 đ`, `150,000 VND`, `1.250.000 VNĐ`), and receipts contain confusing non-total figures such as change return (`Tiền thừa`), discounts (`Giảm giá`), or cash tendered (`Tiền khách đưa`).
* **Resolution:** Designed a multi-pass heuristic pipeline in `ReceiptParser`:
  1. Searches for strong total payment keywords (`Tổng tiền`, `Thanh toán`, `Tổng cộng`, `Grand Total`, `Amount Due`).
  2. Applies strict negative lookahead to filter out change and discount lines.
  3. Parses numeric patterns containing both `.` and `,` thousand separators, casting safely into raw integer VND.
  4. Detects multiple date formats (`dd/MM/yyyy`, `yyyy-MM-dd`, and `Ngày dd Tháng MM Năm yyyy`) while verifying calendar validity (day 1–31, month 1–12).

### Challenge 2: Pure Canvas Data Visualization Without Third-Party Libraries
* **Problem:** To satisfy strict assignment requirements, all data charts had to be drawn from scratch using Flutter's native Canvas API without packages like `fl_chart` or `syncfusion`.
* **Resolution:** Developed two dedicated `CustomPainter` implementations:
  1. **`AnimatedDonutChart`:** Computed arc sweep angles using trigonometric ratios (`value / total * 2 * pi`), introduced angular gap separations (`0.04 rad`) with `StrokeCap.round`, and linked the painting progress to an `AnimationController` with `CurvedAnimation(Curves.easeOutCubic)` for fluid 1-second entrance transitions.
  2. **`WeeklySpendingChart`:** Dynamically calculated coordinate spaces, computed maximum values to scale Y-axis bounds, drew horizontal grid dividing lines with `canvas.drawLine`, rendered rounded gradient bars using `RRect.fromRectAndRadius`, and rendered formatted currency strings and dates with `TextPainter`.

### Challenge 3: MaterialLocalizations Crash on Vietnamese Date Selection
* **Problem:** Triggering `showDatePicker` with `Locale('vi', 'VN')` caused an immediate uncaught `FlutterError: No MaterialLocalizations found`, causing the date selection dialog to fail to appear because the project lacked localization delegates.
* **Resolution:** Added `flutter_localizations: sdk: flutter` to `pubspec.yaml`, registered `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate` in `MaterialApp`, and bounded `firstDate` / `lastDate` (`DateTime(2000)` to `DateTime(2100)`) with graceful try-catch fallback handling.
