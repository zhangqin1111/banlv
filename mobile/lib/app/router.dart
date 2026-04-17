import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/blind_box/blind_box_page.dart';
import '../features/growth/momo_growth_page.dart';
import '../features/home/main_tab_shell.dart';
import '../features/modes/anger_mode/anger_mode_page.dart';
import '../features/modes/joy_mode/joy_mode_page.dart';
import '../features/modes/low_mode/low_mode_page.dart';
import '../features/mood_weather/mood_weather_page.dart';
import '../features/safety/safety_block_page.dart';
import '../features/settings/privacy_page.dart';
import '../features/settings/report_page.dart';
import '../features/settings/settings_page.dart';
import '../features/splash/splash_page.dart';
import '../features/treehole/treehole_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) =>
          const MainTabShell(currentIndex: 0),
    ),
    GoRoute(
      path: '/today',
      builder: (BuildContext context, GoRouterState state) =>
          const MainTabShell(currentIndex: 1),
    ),
    GoRoute(
      path: '/me',
      builder: (BuildContext context, GoRouterState state) =>
          const MainTabShell(currentIndex: 2),
    ),
    GoRoute(
      path: '/treehole',
      builder: (BuildContext context, GoRouterState state) =>
          const TreeholePage(),
    ),
    GoRoute(
      path: '/mood-weather',
      builder: (BuildContext context, GoRouterState state) =>
          const MoodWeatherPage(),
    ),
    GoRoute(
      path: '/mode/joy',
      builder: (BuildContext context, GoRouterState state) =>
          const JoyModePage(),
    ),
    GoRoute(
      path: '/mode/low',
      builder: (BuildContext context, GoRouterState state) =>
          const LowModePage(),
    ),
    GoRoute(
      path: '/mode/anger',
      builder: (BuildContext context, GoRouterState state) =>
          const AngerModePage(),
    ),
    GoRoute(
      path: '/blind-box',
      builder: (BuildContext context, GoRouterState state) =>
          const BlindBoxPage(),
    ),
    GoRoute(
      path: '/growth',
      builder: (BuildContext context, GoRouterState state) =>
          const MomoGrowthPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsPage(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (BuildContext context, GoRouterState state) =>
          const PrivacyPage(),
    ),
    GoRoute(
      path: '/report',
      builder: (BuildContext context, GoRouterState state) =>
          const ReportPage(),
    ),
    GoRoute(
      path: '/safety',
      builder: (BuildContext context, GoRouterState state) =>
          const SafetyBlockPage(),
    ),
  ],
);
