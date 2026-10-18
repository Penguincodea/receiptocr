import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';
import '../state/expense_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final String? initialMerchant;
  final int? initialAmount;
  final DateTime? initialDate;
  final String? initialCategory;
  final String? initialNote;
  final int? existingId;

  const ReviewScreen({
    super.key,
    this.imagePath,
    this.initialMerchant,
    this.initialAmount,
    this.initialDate,
    this.initialCategory,
    this.initialNote,
    this.existingId,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _isSaving = false;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.initialMerchant ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialAmount != null && widget.initialAmount! > 0
          ? widget.initialAmount.toString()
          : '',
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedCategory = widget.initialCategory ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    try {
      DateTime initial = _selectedDate;
      if (initial.isBefore(DateTime(2000))) {
        initial = DateTime(2000);
      } else if (initial.isAfter(DateTime(2100))) {
        initial = DateTime.now();
      }

      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        locale: const Locale('vi', 'VN'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF4F46E5),
                onPrimary: Colors.white,
                onSurface: Colors.grey.shade900,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      debugPrint('Error showing Vietnamese date picker: $e');
      if (!mounted) return;
      try {
        final fallbackPicked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (fallbackPicked != null && mounted) {
          setState(() {
            _selectedDate = fallbackPicked;
          });
        }
      } catch (err) {
        debugPrint('Fallback date picker failed: $err');
      }
    }
  }

  void _showImagePreviewDialog() {
    if (widget.imagePath == null || !File(widget.imagePath!).existsSync()) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.file(File(widget.imagePath!), fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền phải lớn hơn 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final expenseItem = ExpenseItem(
      id: widget.existingId,
      merchantName: _merchantController.text.trim(),
      amount: parsedAmount,
      date: dateStr,
      category: _selectedCategory,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      receiptImagePath: widget.imagePath,
    );

    bool success;
    if (widget.existingId != null) {
      success = await ref
          .read(expenseProvider.notifier)
          .updateExpense(expenseItem);
    } else {
      success = await ref
          .read(expenseProvider.notifier)
          .addExpense(expenseItem);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Đã lưu giao dịch thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu giao dịch. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.imagePath != null && File(widget.imagePath!).existsSync();
    final rawAmountText = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final currentAmountVal = int.tryParse(rawAmountText) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingId != null
              ? 'Chỉnh sửa giao dịch'
              : 'Xác nhận thông tin',
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Receipt image preview thumbnail
              if (hasImage) ...[
                InkWell(
                  onTap: _showImagePreviewDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Center(
                          child: Image.file(
                            File(widget.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.2)),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Chạm để xem ảnh hóa đơn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Merchant name
              const Text(
                'Tên cửa hàng / Đơn vị',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  hintText: 'VD: Highlands Coffee, Co.opmart...',
                  prefixIcon: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên cửa hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Total Amount
              const Text(
                'Tổng tiền thanh toán (VND)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF64748B),
                  ),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                  helperText: currentAmountVal > 0
                      ? 'Định dạng: ${_currencyFormatter.format(currentAmountVal)}'
                      : 'Nhập số tiền hóa đơn',
                  helperStyle: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final num = int.tryParse(
                    val.replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  if (num == null || num <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Date
              GestureDetector(
                onTap: _pickDate,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ngày giao dịch',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dateFormatter.format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Category Selector
              const Text(
                'Danh mục chi tiêu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.all.map((code) {
                  final isSelected = _selectedCategory == code;
                  final color = ExpenseCategory.getColor(code);
                  final name = ExpenseCategory.getDisplayName(code);
                  final icon = ExpenseCategory.getIcon(code);

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 6),
                        Text(name),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? color : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = code;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Note
              const Text(
                'Ghi chú (Tùy chọn)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'VD: Ăn trưa với đồng nghiệp...',
                  prefixIcon: const Icon(
                    Icons.notes_outlined,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Actions
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Lưu giao dịch',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
