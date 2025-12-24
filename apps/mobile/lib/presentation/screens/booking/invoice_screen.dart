import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/payment_datasource.dart';

/// Invoice screen shown when booking is pending_payment
/// Customer can view final price and pay via selected method
class InvoiceScreen extends StatefulWidget {
  final String bookingId;

  const InvoiceScreen({super.key, required this.bookingId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final PaymentDataSource _paymentDataSource = PaymentDataSource();

  Map<String, dynamic>? _invoice;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final invoice = await _paymentDataSource.getInvoice(widget.bookingId);
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _payWithMomo() async {
    if (_invoice == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _paymentDataSource.payWithMomo(widget.bookingId);

      // Open MoMo app or web
      final payUrl = result['payUrl'] as String?;
      final deeplink = result['deeplink'] as String?;

      if (deeplink != null && deeplink.isNotEmpty) {
        final uri = Uri.parse(deeplink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (payUrl != null) {
          await launchUrl(Uri.parse(payUrl),
              mode: LaunchMode.externalApplication);
        }
      } else if (payUrl != null) {
        await launchUrl(Uri.parse(payUrl),
            mode: LaunchMode.externalApplication);
      }

      // Reload invoice after returning
      await Future.delayed(const Duration(seconds: 2));
      _loadInvoice();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Hóa đơn thanh toán'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Không thể tải hóa đơn',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoice,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_invoice == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final pricing = _invoice!['pricing'] as Map<String, dynamic>? ?? {};
    final service = _invoice!['service'] as Map<String, dynamic>? ?? {};
    final provider = _invoice!['provider'] as Map<String, dynamic>? ?? {};
    final status = _invoice!['status'] as String? ?? '';
    final paymentStatus = _invoice!['paymentStatus'] as String? ?? '';
    final paymentMethod = _invoice!['paymentMethod'] as String? ?? '';

    final estimatedPrice = (pricing['estimatedPrice'] ?? 0).toDouble();
    final actualPrice = (pricing['actualPrice'] ?? 0).toDouble();
    final additionalCosts = (pricing['additionalCosts'] ?? 0).toDouble();
    final platformFee = (pricing['platformFee'] ?? 0).toDouble();
    final totalAmount = (pricing['totalAmount'] ?? 0).toDouble();

    final isPaid = paymentStatus == 'paid';
    final isPendingPayment = status == 'pending_payment';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _buildStatusBanner(status, paymentStatus),
          const SizedBox(height: 20),

          // Service info
          _buildInfoCard(
            title: 'Thông tin dịch vụ',
            icon: Icons.home_repair_service,
            children: [
              _buildInfoRow('Mã đơn', _invoice!['bookingCode'] ?? ''),
              _buildInfoRow('Dịch vụ', service['name'] ?? ''),
              _buildInfoRow('Nhà cung cấp', provider['name'] ?? ''),
            ],
          ),
          const SizedBox(height: 16),

          // Pricing breakdown
          _buildPricingCard(
            estimatedPrice: estimatedPrice,
            actualPrice: actualPrice,
            additionalCosts: additionalCosts,
            additionalNotes: pricing['additionalNotes'] as String?,
            platformFee: platformFee,
            totalAmount: totalAmount,
          ),
          const SizedBox(height: 16),

          // Payment method
          _buildPaymentMethodCard(paymentMethod),
          const SizedBox(height: 24),

          // Action buttons
          if (isPendingPayment && !isPaid) ...[
            if (paymentMethod == 'momo' || paymentMethod == 'MOMO')
              _buildMomoPayButton()
            else
              _buildCodInfo(),
          ] else if (isPaid) ...[
            _buildPaidSuccess(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status, String paymentStatus) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (paymentStatus == 'paid') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
      text = 'Đã thanh toán';
    } else if (status == 'pending_payment') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.pending;
      text = 'Chờ thanh toán';
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.info;
      text = 'Đang xử lý';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (status == 'pending_payment' && paymentStatus != 'paid')
                  Text(
                    'Vui lòng thanh toán để hoàn tất dịch vụ',
                    style: TextStyle(
                        color: textColor.withOpacity(0.8), fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required double estimatedPrice,
    required double actualPrice,
    required double additionalCosts,
    String? additionalNotes,
    required double platformFee,
    required double totalAmount,
  }) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryLight.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Chi tiết thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          if (estimatedPrice > 0 && actualPrice != estimatedPrice) ...[
            _buildPriceRow('Giá ước tính', estimatedPrice,
                isStrikethrough: actualPrice > 0),
            const SizedBox(height: 6),
          ],
          if (actualPrice > 0) ...[
            _buildPriceRow('Giá thực tế', actualPrice),
            const SizedBox(height: 6),
          ] else ...[
            _buildPriceRow('Giá dịch vụ', estimatedPrice),
            const SizedBox(height: 6),
          ],
          if (additionalCosts > 0) ...[
            _buildPriceRow('Chi phí phát sinh', additionalCosts,
                color: Colors.orange.shade700),
            if (additionalNotes != null && additionalNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '→ $additionalNotes',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
          _buildPriceRow('Phí nền tảng (10%)', platformFee, isSubtle: true),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                formatter.format(totalAmount),
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isSubtle = false, bool isStrikethrough = false, Color? color}) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? (isSubtle ? Colors.grey.shade600 : Colors.black87),
            fontSize: isSubtle ? 13 : 14,
          ),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            color: color ?? (isSubtle ? Colors.grey.shade600 : Colors.black87),
            fontWeight: FontWeight.w500,
            fontSize: isSubtle ? 13 : 14,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String method) {
    final isCod = method.toUpperCase() == 'COD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCod
                  ? Colors.green.shade50
                  : const Color(0xFFAE2070).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCod ? Icons.payments : Icons.phone_android,
              color: isCod ? Colors.green : const Color(0xFFAE2070),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  isCod ? 'Tiền mặt (COD)' : 'Ví MoMo',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomoPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _payWithMomo,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.phone_android),
        label: Text(_isProcessing ? 'Đang xử lý...' : 'Thanh toán qua MoMo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAE2070),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCodInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.green.shade700, size: 32),
          const SizedBox(height: 8),
          Text(
            'Thanh toán tiền mặt',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vui lòng thanh toán trực tiếp cho nhà cung cấp dịch vụ.\nSau khi nhận tiền, họ sẽ xác nhận hoàn tất.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidSuccess() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle,
                color: Colors.green.shade700, size: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'Thanh toán thành công!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cảm ơn bạn đã sử dụng dịch vụ',
            style: TextStyle(color: Colors.green.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/user/bookings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade300),
            ),
            child: const Text('Xem đơn hàng của tôi'),
          ),
        ],
      ),
    );
  }
}
