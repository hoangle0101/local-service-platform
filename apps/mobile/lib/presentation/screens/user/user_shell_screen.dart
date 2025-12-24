import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/animated_bottom_nav_item.dart';

class UserShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const UserShellScreen({
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Trang chủ',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                AnimatedBottomNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Đơn hàng',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                  badgeCount: 0, // TODO: Get from bloc
                ),
                AnimatedBottomNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Yêu thích',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  badgeCount: 0, // TODO: Get from favorites bloc
                ),
                AnimatedBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Hồ sơ',
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
