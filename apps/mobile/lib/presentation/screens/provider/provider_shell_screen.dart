import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/animated_bottom_nav_item.dart';

class ProviderShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ProviderShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
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
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Thu nhập',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Hoạt động',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  badgeCount: 0, // TODO: Get from bookings bloc
                ),
                AnimatedBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Tài khoản',
                  isSelected: navigationShell.currentIndex == 3,
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
