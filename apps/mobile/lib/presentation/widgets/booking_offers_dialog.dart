import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/bookings_datasource.dart';
import '../bloc/bookings/bookings_event_state.dart';

/// Dialog to show booking offers from providers
/// Allows customer to select a provider
class BookingOffersDialog extends StatefulWidget {
  final String bookingId;
  final VoidCallback onProviderSelected;

  const BookingOffersDialog({
    super.key,
    required this.bookingId,
    required this.onProviderSelected,
  });

  @override
  State<BookingOffersDialog> createState() => _BookingOffersDialogState();
}

class _BookingOffersDialogState extends State<BookingOffersDialog> {
  final BookingsDataSource _datasource = BookingsDataSource();

  List<BookingOffer> _offers = [];
  bool _isLoading = true;
  bool _isSelecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
          '[BookingOffersDialog] Loading offers for bookingId: ${widget.bookingId}');
      final offers =
          await _datasource.getBookingOffers(int.parse(widget.bookingId));
      print('[BookingOffersDialog] Loaded ${offers.length} offers');
      for (var offer in offers) {
        print(
            '[BookingOffersDialog] Offer: id=${offer.id}, provider=${offer.providerName}, price=${offer.price}');
      }
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      print('[BookingOffersDialog] Error loading offers: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectProvider(BookingOffer offer) async {
    setState(() => _isSelecting = true);

    try {
      await _datasource.selectProvider(
        int.parse(widget.bookingId),
        offer.providerId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Đã chọn ${offer.providerName}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProviderSelected();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Báo giá từ thợ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text('Lỗi: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadOffers, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có thợ nào báo giá',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chờ các thợ xem và gửi báo giá cho bạn',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      itemCount: _offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildOfferCard(_offers[index]),
    );
  }

  Widget _buildOfferCard(BookingOffer offer) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isAccepted = offer.status.toUpperCase() == 'ACCEPTED';
    final isPending = offer.status.toUpperCase() == 'PENDING';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccepted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted ? Colors.green : Colors.grey.shade200,
          width: isAccepted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (offer.providerName.isNotEmpty ? offer.providerName[0] : '?')
                      .toUpperCase(),
                  style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.providerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (offer.distance != null)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${(offer.distance! / 1000).toStringAsFixed(1)} km',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (offer.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      offer.rating?.toStringAsFixed(1) ??
                          'N/A', // Removed double.tryParse
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Price and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Báo giá',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(
                    formatter.format(offer.price), // Removed double.tryParse
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              if (isAccepted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Đã chọn',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else if (isPending)
                ElevatedButton(
                  onPressed: _isSelecting ? null : () => _selectProvider(offer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _isSelecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Chọn thợ này'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
