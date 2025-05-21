// router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:accountable/presentation/pages/home_page.dart';
import 'package:accountable/presentation/pages/file_upload_screen.dart';
import 'package:accountable/presentation/pages/summary_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const HomePage(detailsPath: '/transaction_details'),
              routes: [
                GoRoute(
                  path: 'upload',
                  builder: (context, state) => const FileUploadScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/new',
              builder: (context, state) => const FileUploadScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/summary',
              builder: (context, state) => const BudgetSummaryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);



class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountable'),
        actions: navigationShell.currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    context.go('/home/upload');
                  },
                ),
              ]
            : null,
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.new_label), label: 'New'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Summary'),
        ],
      ),
    );
  }
}
