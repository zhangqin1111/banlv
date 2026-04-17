import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../records/records_page.dart';
import '../settings/me_page.dart';
import 'home_page.dart';

class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const HomePage(),
      const RecordsPage(),
      const MePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: NavigationBar(
              height: 74,
              selectedIndex: currentIndex,
              backgroundColor: Colors.white.withValues(alpha: 0.78),
              indicatorColor: AppColors.peachGlow.withValues(alpha: 0.9),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (int index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                  case 1:
                    context.go('/today');
                  case 2:
                    context.go('/me');
                }
              },
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  label: '小岛',
                ),
                NavigationDestination(
                  icon: Icon(Icons.water_drop_rounded),
                  label: '痕迹',
                ),
                NavigationDestination(
                  icon: Icon(Icons.face_retouching_natural_rounded),
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
