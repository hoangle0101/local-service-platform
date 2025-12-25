import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/quote_datasource.dart';
import '../../widgets/minimalist_widgets.dart';

class CreateQuoteScreen extends StatefulWidget {
  final String bookingId;
  final String? serviceName;

  const CreateQuoteScreen({
    super.key,
    required this.bookingId,
    this.serviceName,
  });

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _laborCostController = TextEditingController(text: '0');
  final _warrantyController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _notesController = TextEditingController();

  List<QuoteItem> _items = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _laborCostController.dispose();
    _warrantyController.dispose();
    _estimatedTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _partsCost =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int get _laborCost => int.tryParse(_laborCostController.text) ?? 0;
  int get _totalCost => _partsCost + _laborCost;
  int get _platformFee => (_totalCost * 0.1).round();
  int get _finalPrice => _totalCost + _platformFee;

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddItemSheet(
        onAdd: (item) {
          setState(() => _items.add(item));
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 mục dịch vụ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quoteDataSource = QuoteDataSource();
      await quoteDataSource.createQuote(
        bookingId: widget.bookingId,
        diagnosis: _diagnosisController.text,
        items: _items
            .map((i) => {
                  'name': i.name,
                  'price': i.price,
                  'quantity': i.quantity,
                })
            .toList(),
        laborCost: _laborCost,
        warranty: _warrantyController.text.isNotEmpty
            ? _warrantyController.text
            : null,
        estimatedTime: int.tryParse(_estimatedTimeController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi báo giá cho khách hàng!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo Báo Giá'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Service name
            if (widget.serviceName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.build_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.serviceName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Diagnosis
            _buildSectionTitle('Mô tả tình trạng / Lỗi'),
            const SizedBox(height: 8),
            MinTextField(
              controller: _diagnosisController,
              hint: 'Vd: Máy lạnh không lạnh, gas yếu, cần bổ sung gas...',
              maxLines: 3,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Vui lòng mô tả tình trạng' : null,
            ),

            const SizedBox(height: 24),

            // Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Chi tiết dịch vụ / Linh kiện'),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.shelf,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 40, color: AppColors.textTertiary),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có mục nào',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${_formatCurrency(item.price)} x ${item.quantity}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(item.price * item.quantity),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeItem(index),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Labor cost
            _buildSectionTitle('Công sửa chữa'),
            const SizedBox(height: 8),
            MinTextField(
              controller: _laborCostController,
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('VNĐ',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 24),

            // Warranty & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Bảo hành'),
                      const SizedBox(height: 8),
                      MinTextField(
                        controller: _warrantyController,
                        hint: 'Vd: 3 tháng',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Thời gian (phút)'),
                      const SizedBox(height: 8),
                      MinTextField(
                        controller: _estimatedTimeController,
                        hint: 'Vd: 60',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notes
            _buildSectionTitle('Ghi chú'),
            const SizedBox(height: 8),
            MinTextField(
              controller: _notesController,
              hint: 'Ghi chú thêm cho khách hàng...',
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Linh kiện / Dịch vụ', _partsCost),
                  _buildSummaryRow('Công sửa chữa', _laborCost),
                  const Divider(height: 24),
                  _buildSummaryRow('Tạm tính', _totalCost),
                  _buildSummaryRow('Phí nền tảng (10%)', _platformFee,
                      isSubtle: true),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatCurrency(_finalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            MinButton(
              text: 'Gửi Báo Giá',
              isLoading: _isSubmitting,
              isFullWidth: true,
              onPressed: _submitQuote,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isSubtle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isSubtle ? AppColors.textTertiary : AppColors.textSecondary,
              fontSize: isSubtle ? 13 : 14,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: isSubtle ? FontWeight.normal : FontWeight.w600,
              color: isSubtle ? AppColors.textTertiary : AppColors.textPrimary,
              fontSize: isSubtle ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Quote item model
class QuoteItem {
  final String name;
  final int price;
  final int quantity;

  QuoteItem({required this.name, required this.price, required this.quantity});
}

// Add item sheet
class _AddItemSheet extends StatefulWidget {
  final Function(QuoteItem) onAdd;

  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _add() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      return;
    }

    widget.onAdd(QuoteItem(
      name: _nameController.text,
      price: int.tryParse(_priceController.text) ?? 0,
      quantity: int.tryParse(_quantityController.text) ?? 1,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thêm mục dịch vụ / linh kiện',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          MinTextField(
            controller: _nameController,
            label: 'Tên mục',
            hint: 'Vd: Thay gas máy lạnh R32',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: MinTextField(
                  controller: _priceController,
                  label: 'Đơn giá (VNĐ)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MinTextField(
                  controller: _quantityController,
                  label: 'SL',
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          MinButton(
            text: 'Thêm',
            isFullWidth: true,
            onPressed: _add,
          ),
        ],
      ),
    );
  }
}
