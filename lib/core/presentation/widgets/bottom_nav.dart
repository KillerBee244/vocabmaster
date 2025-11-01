import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routing/app_routes.dart';
import '../theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int selected;
  const BottomNav({super.key, required this.selected});

  void _onTap(BuildContext context, int i) {
    if (i == selected) return;
    switch (i) {
      case 0: context.go(AppRoutes.home); break;
      case 1: context.go(AppRoutes.topics); break;
      case 2: context.go(AppRoutes.library); break;
      case 3: context.go(AppRoutes.practice); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.9),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(.12),
          selectedIndex: selected,
          onDestinationSelected: (i) => _onTap(context, i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Chủ đề'),
            NavigationDestination(icon: Icon(Icons.folder_open_outlined), selectedIcon: Icon(Icons.folder), label: 'Thư viện'),
            NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'Luyện tập'),
          ],
        ),
      ),
    );
  }
}
