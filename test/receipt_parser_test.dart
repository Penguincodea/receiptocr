import 'package:flutter_test/flutter_test.dart';
import 'package:receiptocr/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests', () {
    test('Parse amount with 150,000 VND format', () {
      const sample = '''
      HIGHLANDS COFFEE
      Ngày: 15/08/2024
      1 Freeze Tra Xanh   55,000
      1 Phin Sua Da       45,000
      Tổng tiền: 150,000 VND
      Tiền khách đưa: 200,000 VND
      Tiền thừa: 50,000 VND
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, 150000);
      expect(result.merchantName, 'HIGHLANDS COFFEE');
      expect(result.date, DateTime(2024, 8, 15));
    });

    test('Parse amount with 150.000 đ format', () {
      const sample = '''
      PHÚC LONG COFFEE & TEA
      Đ/C: 123 Nguyen Hue, Q1, TP.HCM
      Ngày: 20-11-2024
      Thanh toán: 150.000 đ
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, 150000);
      expect(result.merchantName, 'PHÚC LONG COFFEE & TEA');
      expect(result.date, DateTime(2024, 11, 20));
    });

    test('Parse amount with 1.250.000 VNĐ format', () {
      const sample = '''
      NHÀ SÁCH FAHASA
      HÓA ĐƠN BÁN HÀNG
      Ngày: 05/01/2025
      Sách giáo trình: 1.250.000
      Tổng cộng: 1.250.000 VNĐ
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, 1250000);
      expect(result.merchantName, 'NHÀ SÁCH FAHASA');
      expect(result.date, DateTime(2025, 1, 5));
    });

    test('Parse amount with "Tổng tiền: 150000"', () {
      const sample = '''
      CIRCLE K VIETNAM
      Ngày 12 tháng 05 năm 2024
      Tổng tiền: 150000
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, 150000);
      expect(result.merchantName, 'CIRCLE K VIETNAM');
      expect(result.date, DateTime(2024, 5, 12));
    });

    test('Parse amount with "Thành tiền: 50.000"', () {
      const sample = '''
      Quán Cơm Tấm Ba Ghiền
      Ngày: 2024-09-10
      Thành tiền: 50.000
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, 50000);
      expect(result.merchantName, 'Quán Cơm Tấm Ba Ghiền');
      expect(result.date, DateTime(2024, 9, 10));
    });

    test('Parse amount with English keywords "Grand Total: 350.000"', () {
      const sample = '''
      STARBUCKS COFFEE
      Date: 10/10/2024
      Subtotal: 300.000
      VAT (10%): 30.000
      Service: 20.000
      Grand Total: 350.000
      Cash Given: 500.000
      Change: 150.000
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, 350000);
      expect(result.merchantName, 'STARBUCKS COFFEE');
      expect(result.date, DateTime(2024, 10, 10));
    });

    test('Empty or unidentifiable receipt returns nulls and no fake data', () {
      const sample = '''
      Xin chao quy khach
      Chuc mot ngay tot lanh
      ''';

      final result = ReceiptParser.parse(sample);
      expect(result.amount, isNull);
      expect(result.date, isNull);
    });
  });
}
