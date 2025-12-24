import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/animated_bottom_nav_item.dart';
import '../../../core/services/socket_service.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../theme/app_colors.dart';

class UserShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const UserShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService();

    socket.on('booking.new_offer', (data) {
      if (!mounted) return;
      _showNotification(
        'Bạn nhận được báo giá mới!',
        icon: Icons.local_offer_rounded,
        color: Colors.blue,
      );
      context.read<BookingsBloc>().add(const LoadUserBookingsEvent());
    });

    socket.on('booking.started', (data) {
      if (!mounted) return;
      _showNotification(
        'Thợ đã bắt đầu công việc!',
        icon: Icons.play_arrow_rounded,
        color: Colors.green,
      );
      context.read<BookingsBloc>().add(const LoadUserBookingsEvent());
    });

    socket.on('booking.completed', (data) {
      if (!mounted) return;
      _showNotification(
        'Công việc đã hoàn thành. Hãy xác nhận!',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      );
      context.read<BookingsBloc>().add(const LoadUserBookingsEvent());
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
    socket.off('booking.new_offer');
    socket.off('booking.started');
    socket.off('booking.completed');
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Trang chủ',
                  isSelected: widget.navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Đơn hàng',
                  isSelected: widget.navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                  badgeCount: 0,
                ),
                AnimatedBottomNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Yêu thích',
                  isSelected: widget.navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  badgeCount: 0,
                ),
                AnimatedBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Hồ sơ',
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
