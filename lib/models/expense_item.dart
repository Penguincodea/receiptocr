import 'package:flutter/material.dart';

class ExpenseCategory {
  static const String food = 'food';
  static const String study = 'study';
  static const String travel = 'travel';
  static const String gear = 'gear';
  static const String entertainment = 'entertainment';

  static const List<String> all = [food, study, travel, gear, entertainment];

  static String getDisplayName(String code) {
    switch (code) {
      case food:
        return 'Ăn uống';
      case study:
        return 'Học tập';
      case travel:
        return 'Di chuyển';
      case gear:
        return 'Đồ dùng/Thiết bị';
      case entertainment:
        return 'Giải trí';
      default:
        return 'Khác';
    }
  }

  static IconData getIcon(String code) {
    switch (code) {
      case food:
        return Icons.restaurant;
      case study:
        return Icons.school;
      case travel:
        return Icons.directions_car;
      case gear:
        return Icons.devices;
      case entertainment:
        return Icons.sports_esports;
      default:
        return Icons.receipt_long;
    }
  }

  static Color getColor(String code) {
    switch (code) {
      case food:
        return const Color(0xFFEF4444); // Red
      case study:
        return const Color(0xFF3B82F6); // Blue
      case travel:
        return const Color(0xFF10B981); // Emerald Green
      case gear:
        return const Color(0xFFF59E0B); // Amber / Orange
      case entertainment:
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

class ExpenseItem {
  final int? id;
  final String merchantName;
  final int amount; // in VND
  final String date; // YYYY-MM-DD
  final String category;
  final String? note;
  final String? receiptImagePath;
  final String createdAt; // ISO string

  ExpenseItem({
    this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    this.receiptImagePath,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant_name': merchantName,
      'amount': amount,
      'date': date,
      'category': category,
      'note': note ?? '',
      'receipt_image_path': receiptImagePath ?? '',
      'created_at': createdAt,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int?,
      merchantName: (map['merchant_name'] as String?) ?? 'Không rõ',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      date:
          (map['date'] as String?) ??
          DateTime.now().toIso8601String().substring(0, 10),
      category: (map['category'] as String?) ?? ExpenseCategory.food,
      note: map['note'] as String?,
      receiptImagePath:
          (map['receipt_image_path'] as String?)?.isNotEmpty == true
          ? map['receipt_image_path'] as String
          : null,
      createdAt:
          (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }

  ExpenseItem copyWith({
    int? id,
    String? merchantName,
    int? amount,
    String? date,
    String? category,
    String? note,
    String? receiptImagePath,
    String? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
