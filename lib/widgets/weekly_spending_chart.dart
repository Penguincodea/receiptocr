import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../state/expense_provider.dart';

class WeeklySpendingChart extends StatefulWidget {
  final List<DailySpending> weeklyData;
  final double height;

  const WeeklySpendingChart({
    super.key,
    required this.weeklyData,
    this.height = 200,
  });

  @override
  State<WeeklySpendingChart> createState() => _WeeklySpendingChartState();
}

class _WeeklySpendingChartState extends State<WeeklySpendingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklySpendingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weeklyData != oldWidget.weeklyData) {
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
    final currencyFormat = NumberFormat.compact(locale: 'vi_VN');
    final totalWeekly = widget.weeklyData.fold<int>(
      0,
      (sum, d) => sum + d.amount,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiêu 7 ngày qua',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalWeekly)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _WeeklyBarChartPainter(
                    weeklyData: widget.weeklyData,
                    progress: _animation.value,
                    compactCurrencyFormat: currencyFormat,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<DailySpending> weeklyData;
  final double progress;
  final NumberFormat compactCurrencyFormat;

  _WeeklyBarChartPainter({
    required this.weeklyData,
    required this.progress,
    required this.compactCurrencyFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;

    final bottomAxisHeight = 28.0;
    final topPadding = 18.0;
    final chartHeight = size.height - bottomAxisHeight - topPadding;
    final chartWidth = size.width;

    final maxVal = weeklyData.map((e) => e.amount).fold<int>(0, max);
    // If all are 0, use 100k as baseline ceiling so bars render nicely at 0
    final double ceiling = maxVal > 0 ? (maxVal * 1.15).toDouble() : 100000.0;

    // 1. Draw horizontal gridlines (3 lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * (1.0 - (i / 3.0)));
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 2. Draw bars
    final barCount = weeklyData.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = min(slotWidth * 0.55, 26.0);

    for (int i = 0; i < barCount; i++) {
      final item = weeklyData[i];
      final slotCenterX = (i * slotWidth) + (slotWidth / 2);
      final left = slotCenterX - (barWidth / 2);
      final right = left + barWidth;

      final normalizedHeight = (item.amount / ceiling) * chartHeight * progress;
      final bottomY = topPadding + chartHeight;
      final topY = bottomY - normalizedHeight;

      // Draw background bar slot (light grey)
      final slotBgPaint = Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill;
      final slotRRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, topPadding, right, bottomY),
        const Radius.circular(6),
      );
      canvas.drawRRect(slotRRect, slotBgPaint);

      // Draw actual bar with gradient
      if (item.amount > 0 && normalizedHeight > 0) {
        final isLatest = i == barCount - 1; // Today
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isLatest
                ? [const Color(0xFF4F46E5), const Color(0xFF818CF8)]
                : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
          ).createShader(Rect.fromLTRB(left, topY, right, bottomY))
          ..style = PaintingStyle.fill;

        final barRRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(left, topY, right, bottomY),
          const Radius.circular(6),
        );
        canvas.drawRRect(barRRect, barPaint);

        // Draw amount text above bar if animated
        if (progress > 0.8) {
          final textSpan = TextSpan(
            text: compactCurrencyFormat.format(item.amount),
            style: TextStyle(
              color: isLatest
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF475569),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();

          textPainter.paint(
            canvas,
            Offset(
              slotCenterX - (textPainter.width / 2),
              max(0, topY - textPainter.height - 3),
            ),
          );
        }
      }

      // 3. Draw date label on the X axis
      final labelSpan = TextSpan(
        text: item.dayLabel,
        style: TextStyle(
          color: i == barCount - 1
              ? const Color(0xFF4F46E5)
              : const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: i == barCount - 1 ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(slotCenterX - (labelPainter.width / 2), bottomY + 6),
      );
    }

    // 4. If all values are 0, draw friendly watermark note in center
    if (maxVal == 0) {
      final emptySpan = TextSpan(
        text: 'Chưa có chi tiêu trong tuần này',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
      final emptyPainter = TextPainter(
        text: emptySpan,
        textDirection: TextDirection.ltr,
      )..layout();

      emptyPainter.paint(
        canvas,
        Offset(
          (chartWidth - emptyPainter.width) / 2,
          topPadding + (chartHeight / 2) - (emptyPainter.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.weeklyData != weeklyData;
  }
}
