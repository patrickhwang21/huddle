import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  /// 0 = Home / Dashboard, 1 = Profile
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECECEF))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                  }
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    Navigator.pushNamed(context, '/profile');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFF8B8D98);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEEF2FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
