class ReceiptParseResult {
  final String? merchantName;
  final int? amount;
  final DateTime? date;
  final String rawText;

  const ReceiptParseResult({
    this.merchantName,
    this.amount,
    this.date,
    required this.rawText,
  });

  @override
  String toString() {
    return 'ReceiptParseResult(merchant: $merchantName, amount: $amount, date: $date)';
  }
}

class ReceiptParser {
  /// Priority keywords indicating the final total payment
  static final List<String> _totalKeywords = [
    'tổng tiền',
    'tong tien',
    'tổng thanh toán',
    'tong thanh toan',
    'tiền thanh toán',
    'tien thanh toan',
    'thanh toán',
    'thanh toan',
    'tổng cộng',
    'tong cong',
    'thành tiền',
    'thanh tien',
    'thực thu',
    'thuc thu',
    'phải thu',
    'phai thu',
    'cần thanh toán',
    'can thanh toan',
    'grand total',
    'amount due',
    'balance due',
    'total amount',
    'net total',
    'total',
  ];

  /// Keywords that should NOT be picked as total (e.g., discounts, cash given, change)
  static final List<String> _subKeywords = [
    'tiền thừa',
    'tien thua',
    'tiền trả lại',
    'tien tra lai',
    'thối lại',
    'thoi lai',
    'giảm giá',
    'giam gia',
    'chiết khấu',
    'chiet khau',
    'discount',
    'khách đưa',
    'khach dua',
    'tiền khách',
    'tien khach',
    'cash',
    'change',
  ];

  /// Header keywords to ignore when determining merchant name
  static final List<String> _headerIgnoredKeywords = [
    'hóa đơn',
    'hoa don',
    'phiếu thanh toán',
    'phieu thanh toan',
    'hóa đơn bán hàng',
    'hoa don ban hang',
    'phiếu tạm tính',
    'phieu tam tinh',
    'receipt',
    'invoice',
    'vat invoice',
    'bill',
    'order',
    'đơn hàng',
    'don hang',
    'bán lẻ',
    'ban le',
    'tính tiền',
    'tinh tien',
  ];

  /// Parse the entire recognized text of a receipt
  static ReceiptParseResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ReceiptParseResult(rawText: '');
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchantName = _extractMerchantName(lines);
    final amount = _extractAmount(lines);
    final date = _extractDate(lines);

    return ReceiptParseResult(
      merchantName: merchantName,
      amount: amount,
      date: date,
      rawText: rawText,
    );
  }

  /// 1. Extract merchant name from the header lines
  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Check the first 6 lines
    final searchLines = lines.take(6).toList();

    // First check if any line has explicit merchant identifier
    for (final line in searchLines) {
      final lower = line.toLowerCase();
      if (_hasMerchantPrefix(lower)) {
        final cleaned = _cleanMerchantName(line);
        if (cleaned != null && cleaned.length >= 3) {
          return cleaned;
        }
      }
    }

    // Otherwise, pick the first valid non-header, non-info line
    for (final line in searchLines) {
      final lower = line.toLowerCase();

      // Skip generic headers
      if (_isHeaderLine(lower)) continue;

      // Skip lines with phone numbers, tax codes, addresses, or dates
      if (_isContactOrInfoLine(lower)) continue;

      final cleaned = _cleanMerchantName(line);
      if (cleaned != null &&
          cleaned.length >= 3 &&
          _hasAlphabeticChars(cleaned)) {
        return cleaned;
      }
    }

    return null;
  }

  static bool _hasMerchantPrefix(String line) {
    final prefixes = [
      'cửa hàng',
      'cua hang',
      'nhà hàng',
      'nha hang',
      'quán',
      'quan',
      'cafe',
      'coffee',
      'tiệm',
      'tiem',
      'công ty',
      'cong ty',
      'store',
      'shop',
      'restaurant',
      'trà sữa',
      'tra sua',
      'siêu thị',
      'sieu thi',
      'highlands',
      'phúc long',
      'phuc long',
      'circle k',
      'winmart',
      'co.opmart',
      'gs25',
      'ministop',
      '7-eleven',
      'starbucks',
      'lotteria',
      'kfc',
      'jollibee',
      'the coffee house',
    ];
    for (final p in prefixes) {
      if (line.contains(p)) return true;
    }
    return false;
  }

  static bool _isHeaderLine(String line) {
    for (final h in _headerIgnoredKeywords) {
      if (line == h || line.startsWith('$h ') || line.startsWith('$h:')) {
        return true;
      }
    }
    return false;
  }

  static bool _isContactOrInfoLine(String line) {
    if (line.contains('đ/c') ||
        line.contains('địa chỉ') ||
        line.contains('dia chi') ||
        line.contains('address') ||
        line.contains('tel:') ||
        line.contains('sđt:') ||
        line.contains('sdt:') ||
        line.contains('phone:') ||
        line.contains('mst:') ||
        line.contains('mã số thuế') ||
        line.contains('ma so thue') ||
        line.contains('hotline') ||
        line.contains('wifi') ||
        line.contains('pass') ||
        line.contains('http') ||
        line.contains('www.')) {
      return true;
    }
    return false;
  }

  static String? _cleanMerchantName(String line) {
    // Strip common leading words like "Tên CH:", "Nhà hàng:", etc.
    String cleaned = line
        .replaceAll(
          RegExp(
            r'^(cửa hàng|nhà hàng|quán|tiệm|tên ch|tên cty|cty|shop|store)\s*[:\-]\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  static bool _hasAlphabeticChars(String str) {
    return RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(str);
  }

  /// 2. Extract transaction amount
  static int? _extractAmount(List<String> lines) {
    // Strategy A: Look for lines containing total keywords
    for (final keyword in _totalKeywords) {
      for (int i = lines.length - 1; i >= 0; i--) {
        final line = lines[i];
        final lower = line.toLowerCase();

        // Avoid lines with subKeywords (like change/tiền thừa/khách đưa)
        if (_hasSubKeywords(lower)) continue;

        if (lower.contains(keyword)) {
          // Extract amount on this line
          final amount = _parseAmountFromLine(line);
          if (amount != null && amount > 0) {
            return amount;
          }

          // Sometimes the number is on the next line or previous line
          if (i + 1 < lines.length) {
            final nextLineAmount = _parseAmountFromLine(lines[i + 1]);
            if (nextLineAmount != null && nextLineAmount > 0) {
              return nextLineAmount;
            }
          }
        }
      }
    }

    // Strategy B: Lines with currency symbols (VND, đ, VNĐ) from bottom up
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (_hasSubKeywords(lower)) continue;

      if (lower.contains('vnd') ||
          lower.contains('vnđ') ||
          lower.contains('đ') ||
          lower.contains('đồng') ||
          lower.contains('dong')) {
        final amount = _parseAmountFromLine(line);
        if (amount != null && amount >= 1000) {
          return amount;
        }
      }
    }

    // Strategy C: Last standalone numeric value that looks like an amount (>= 1,000)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (_hasSubKeywords(lower)) continue;
      if (_isContactOrInfoLine(lower)) continue;

      final amount = _parseAmountFromLine(line);
      if (amount != null && amount >= 1000 && amount <= 500000000) {
        // Exclude 10-digit phone numbers or 4-digit years
        if (amount < 2035 && amount > 2000) continue;
        return amount;
      }
    }

    return null;
  }

  static bool _hasSubKeywords(String line) {
    for (final sub in _subKeywords) {
      if (line.contains(sub)) return true;
    }
    return false;
  }

  /// Parse number from a single line
  static int? _parseAmountFromLine(String line) {
    // Match patterns like:
    // 150,000 or 150.000 or 1,250,000 or 1.250.000 or 150000
    final regex = RegExp(r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\d{4,9})');
    final matches = regex.allMatches(line);

    for (final match in matches) {
      final matchStr = match.group(0);
      if (matchStr == null) continue;

      final val = _normalizeVndNumber(matchStr);
      if (val != null && val >= 500 && val <= 1000000000) {
        // Filter out typical Vietnamese phone numbers (10 digits starting with 0)
        if (matchStr.length == 10 && matchStr.startsWith('0')) continue;
        return val;
      }
    }

    return null;
  }

  static int? _normalizeVndNumber(String str) {
    // Remove currency texts and extra spaces
    String cleaned = str.trim();

    // Check if it's dotted/comma thousands format: e.g. 150.000 or 150,000 or 1.250.000
    // In VND, standard is thousands separator (. or ,) and no decimal cents.
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(cleaned);
  }

  /// 3. Extract transaction date
  static DateTime? _extractDate(List<String> lines) {
    // Patterns:
    // 1. dd/MM/yyyy or dd-MM-yyyy or dd.MM.yyyy
    // 2. yyyy-MM-dd or yyyy/MM/dd
    // 3. dd/MM/yy or dd-MM-yy
    // 4. Ngày dd tháng MM năm yyyy
    final vietnameseDateRegex = RegExp(
      r'ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(\d{4})',
      caseSensitive: false,
    );

    final standardDateRegex = RegExp(
      r'(\b\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4}\b)',
    );

    final isoDateRegex = RegExp(r'(\b\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2}\b)');

    for (final line in lines) {
      // Check "Ngày dd tháng MM năm yyyy"
      final vnMatch = vietnameseDateRegex.firstMatch(line);
      if (vnMatch != null) {
        final d = int.tryParse(vnMatch.group(1)!);
        final m = int.tryParse(vnMatch.group(2)!);
        final y = int.tryParse(vnMatch.group(3)!);
        final date = _buildValidDate(y, m, d);
        if (date != null) return date;
      }

      // Check ISO format "yyyy-MM-dd"
      final isoMatch = isoDateRegex.firstMatch(line);
      if (isoMatch != null) {
        final y = int.tryParse(isoMatch.group(1)!);
        final m = int.tryParse(isoMatch.group(2)!);
        final d = int.tryParse(isoMatch.group(3)!);
        final date = _buildValidDate(y, m, d);
        if (date != null) return date;
      }

      // Check dd/MM/yyyy
      final stdMatch = standardDateRegex.firstMatch(line);
      if (stdMatch != null) {
        final d = int.tryParse(stdMatch.group(1)!);
        final m = int.tryParse(stdMatch.group(2)!);
        int? y = int.tryParse(stdMatch.group(3)!);
        if (y != null && y < 100) {
          y += 2000;
        }
        final date = _buildValidDate(y, m, d);
        if (date != null) return date;
      }
    }

    return null;
  }

  static DateTime? _buildValidDate(int? y, int? m, int? d) {
    if (y == null || m == null || d == null) return null;
    if (y < 2010 || y > 2035) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    try {
      final dt = DateTime(y, m, d);
      if (dt.month == m && dt.day == d) {
        return dt;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
