import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<String, int> categoryTotals;
  final double size;

  const AnimatedDonutChart({
    super.key,
    required this.categoryTotals,
    this.size = 200,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryTotals != oldWidget.categoryTotals) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final total = widget.categoryTotals.values.fold<int>(0, (a, b) => a + b);

    // Active categories with amount > 0
    final activeCategories = widget.categoryTotals.entries
        .where((e) => e.value > 0)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _DonutChartPainter(
                  categoryTotals: widget.categoryTotals,
                  total: total,
                  progress: _animation.value,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total > 0 ? 'Tổng cộng' : 'Chưa có',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        total > 0 ? currencyFormat.format(total) : '0 ₫',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (activeCategories.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Chưa có dữ liệu chi tiêu để phân loại',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: activeCategories.map((entry) {
              final cat = entry.key;
              final amount = entry.value;
              final color = ExpenseCategory.getColor(cat);
              final name = ExpenseCategory.getDisplayName(cat);
              final pct = total > 0
                  ? (amount / total * 100).toStringAsFixed(1)
                  : '0';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$name ($pct%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, int> categoryTotals;
  final int total;
  final double progress;

  _DonutChartPainter({
    required this.categoryTotals,
    required this.total,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.12;
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw background ring
    canvas.drawCircle(center, radius, backgroundPaint);

    if (total <= 0) {
      return;
    }

    double startAngle = -pi / 2; // Start at 12 o'clock

    for (final entry in categoryTotals.entries) {
      if (entry.value <= 0) continue;

      final category = entry.key;
      final amount = entry.value;
      final sweepAngle = (amount / total) * 2 * pi * progress;

      final paint = Paint()
        ..color = ExpenseCategory.getColor(category)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Draw arc for this category
      // Add subtle margin if there are multiple categories
      final gapAngle = 0.04;
      final adjustedSweep = max(0.0, sweepAngle - gapAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.categoryTotals != categoryTotals;
  }
}
