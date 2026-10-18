import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';
import '../state/expense_provider.dart';
import '../widgets/animated_donut_chart.dart';
import '../widgets/weekly_spending_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    final monthTotal = expenseState.currentMonthTotal;
    final totalAllTime = expenseState.totalAllTime;
    final itemCount = expenseState.items.length;

    // Find highest category
    String? highestCategory;
    int highestCategoryAmount = 0;
    for (final entry in expenseState.categoryTotals.entries) {
      if (entry.value > highestCategoryAmount) {
        highestCategoryAmount = entry.value;
        highestCategory = entry.key;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Metric cards row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Tháng này',
                  value: currencyFormatter.format(monthTotal),
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Tổng tích lũy',
                  value: currencyFormatter.format(totalAllTime),
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Số hóa đơn',
                  value: '$itemCount hóa đơn',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Chi nhiều nhất',
                  value: highestCategory != null
                      ? ExpenseCategory.getDisplayName(highestCategory)
                      : 'Chưa có',
                  icon: Icons.pie_chart_rounded,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Animated Donut Chart
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cơ cấu chi tiêu theo danh mục',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: AnimatedDonutChart(
                    categoryTotals: expenseState.categoryTotals,
                    size: 210,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Weekly Spending Bar Chart
          WeeklySpendingChart(
            weeklyData: expenseState.last7DaysSpending,
            height: 190,
          ),
          const SizedBox(height: 20),

          // 4. Detailed category breakdown list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết từng hạng mục',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...ExpenseCategory.all.map((code) {
                  final amount = expenseState.categoryTotals[code] ?? 0;
                  final name = ExpenseCategory.getDisplayName(code);
                  final color = ExpenseCategory.getColor(code);
                  final icon = ExpenseCategory.getIcon(code);
                  final pct = totalAllTime > 0
                      ? (amount / totalAllTime * 100).toStringAsFixed(1)
                      : '0.0';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '$pct% trên tổng chi',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormatter.format(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
