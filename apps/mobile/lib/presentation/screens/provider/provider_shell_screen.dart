import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/animated_bottom_nav_item.dart';
import '../../../core/services/socket_service.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../theme/app_colors.dart';

class ProviderShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ProviderShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<ProviderShellScreen> createState() => _ProviderShellScreenState();
}

class _ProviderShellScreenState extends State<ProviderShellScreen> {
  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService();

    socket.on('booking.new_request', (data) {
      if (!mounted) return;
      _showNotification(
        'Có yêu cầu đặt việc mới gần bạn!',
        icon: Icons.work_outline_rounded,
        color: Colors.blue,
      );
      context.read<BookingsBloc>().add(const LoadProviderBookings());
    });

    socket.on('booking.accepted', (data) {
      if (!mounted) return;
      _showNotification(
        'Chúc mừng! Bạn đã được nhận việc!',
        icon: Icons.celebration_rounded,
        color: Colors.orange,
      );
      context.read<BookingsBloc>().add(const LoadProviderBookings());

      // Auto redirect to navigation map if location is available
      if (data['latitude'] != null && data['longitude'] != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.push('/provider/navigation', extra: {
              'lat': double.tryParse(data['latitude'].toString()) ?? 0.0,
              'lng': double.tryParse(data['longitude'].toString()) ?? 0.0,
              'address': data['addressText'],
              'customerName': data['customerName'],
            });
          }
        });
      }
    });

    socket.on('booking.confirmed', (data) {
      if (!mounted) return;
      _showNotification(
        'Khách đã xác nhận hoàn thành dịch vụ!',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      );
      context.read<BookingsBloc>().add(const LoadProviderBookings());
    });
  }

  void _showNotification(String message, {IconData? icon, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? AppColors.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    final socket = SocketService();
    socket.off('booking.new_request');
    socket.off('booking.accepted');
    socket.off('booking.confirmed');
    super.dispose();
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AnimatedBottomNavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Trang chủ',
                  isSelected: widget.navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Thu nhập',
                  isSelected: widget.navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Hoạt động',
                  isSelected: widget.navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  badgeCount: 0,
                ),
                AnimatedBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Tài khoản',
                  isSelected: widget.navigationShell.currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
