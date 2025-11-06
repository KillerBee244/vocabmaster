import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../routing/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'Người dùng'),
              accountEmail: Text(user?.email ?? 'Chưa đăng nhập'),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Trang chủ'),
              onTap: () => context.go(AppRoutes.home),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Chủ đề'),
              onTap: () => context.go(AppRoutes.topics),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Thư viện'),
              onTap: () => context.go(AppRoutes.library),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Luyện tập'),
              onTap: () => context.go(AppRoutes.practice),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
