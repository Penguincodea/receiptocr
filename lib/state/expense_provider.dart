import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_item.dart';
import '../services/database_service.dart';

class DailySpending {
  final DateTime date;
  final String dayLabel; // e.g. "T2" or "12/10"
  final int amount;

  const DailySpending({
    required this.date,
    required this.dayLabel,
    required this.amount,
  });
}

class ExpenseState {
  final List<ExpenseItem> items;
  final bool isLoading;
  final String? errorMessage;

  const ExpenseState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ExpenseState copyWith({
    List<ExpenseItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExpenseState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Total spending in the current month (YYYY-MM)
  int get currentMonthTotal {
    final now = DateTime.now();
    final currentMonthPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return items
        .where((item) => item.date.startsWith(currentMonthPrefix))
        .fold(0, (sum, item) => sum + item.amount);
  }

  /// Total spending across all recorded items
  int get totalAllTime {
    return items.fold(0, (sum, item) => sum + item.amount);
  }

  /// Category breakdown: returns Map of `categoryCode` to `totalAmount`
  Map<String, int> get categoryTotals {
    final map = <String, int>{};
    for (final cat in ExpenseCategory.all) {
      map[cat] = 0;
    }
    for (final item in items) {
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
  }

  /// Weekly spending for the last 7 days (including today)
  List<DailySpending> get last7DaysSpending {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = <DailySpending>[];

    // From 6 days ago up to today
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final dayTotal = items
          .where((item) => item.date == dateStr)
          .fold(0, (sum, item) => sum + item.amount);

      final label =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

      list.add(DailySpending(
        date: date,
        dayLabel: label,
        amount: dayTotal,
      ));
    }

    return list;
  }
}

class ExpenseNotifier extends Notifier<ExpenseState> {
  DatabaseService get _dbService => DatabaseService.instance;

  @override
  ExpenseState build() {
    Future.microtask(() => loadExpenses());
    return const ExpenseState();
  }

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _dbService.getAllExpenses();
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải dữ liệu: $e',
      );
    }
  }

  Future<bool> addExpense(ExpenseItem item) async {
    try {
      String? persistentImagePath;
      if (item.receiptImagePath != null && item.receiptImagePath!.isNotEmpty) {
        persistentImagePath =
            await _dbService.saveReceiptImage(item.receiptImagePath!);
      }

      final itemToSave = persistentImagePath != null
          ? item.copyWith(receiptImagePath: persistentImagePath)
          : item;

      final id = await _dbService.insertExpense(itemToSave);
      final newItem = itemToSave.copyWith(id: id);

      state = state.copyWith(
        items: [newItem, ...state.items],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Lỗi lưu giao dịch: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _dbService.deleteExpense(id);
      state = state.copyWith(
        items: state.items.where((e) => e.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Lỗi xóa giao dịch: $e');
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseItem item) async {
    try {
      await _dbService.updateExpense(item);
      state = state.copyWith(
        items: state.items.map((e) => e.id == item.id ? item : e).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Lỗi cập nhật giao dịch: $e');
      return false;
    }
  }
}

final expenseProvider =
    NotifierProvider<ExpenseNotifier, ExpenseState>(ExpenseNotifier.new);
