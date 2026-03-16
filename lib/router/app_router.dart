// lib/router/app_router.dart
// go_router yapılandırması — deep link ve navigasyon

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../screens/home_screen.dart';
import '../screens/guest_home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/city_selection_screen.dart';
import '../screens/neighborhood_detail_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/route_screen.dart';
import '../screens/municipality_dashboard_screen.dart';

class SehirSesRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      // Login gerektiren rotalar
      final protectedRoutes = ['/feedback', '/municipality'];
      final isProtected = protectedRoutes.any((r) => state.matchedLocation.startsWith(r));

      if (isProtected && !isLoggedIn) {
        return '/login?redirect=${state.matchedLocation}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashRedirect(),
      ),
      GoRoute(
        path: '/city-select',
        builder: (context, state) => CitySelectionScreen(
          isFirstTime: state.uri.queryParameters['first'] == 'true',
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const GuestHomeScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/neighborhood/:id',
        builder: (context, state) {
          final parts = (state.pathParameters['id'] ?? '').split('_');
          // Router'dan sadece konum geliyor, stats lazy-load ediliyor
          // NeighborhoodDetailScreen stats bekliyor → geçici sample stats oluştur
          final province = parts.length > 2 ? parts[0] : 'İstanbul';
          final district = parts.length > 2 ? parts[1] : 'Beşiktaş';
          final neighborhood = parts.length > 2 ? parts[2] : (parts.isNotEmpty ? parts[0] : 'Mahalle');
          return NeighborhoodDetailScreen(
            stats: NeighborhoodStats.sample(neighborhood, district),
          );
        },
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => FeedbackScreen(
          preselectedNeighborhood: state.uri.queryParameters['neighborhood'],
        ),
      ),
      GoRoute(
        path: '/route',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return RouteScreen(
            neighborhood: q['neighborhood'] ?? '',
            district: q['district'] ?? '',
            province: q['province'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/municipality',
        builder: (context, state) => const MunicipalityDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Sayfa bulunamadı: ${state.error}'),
      ),
    ),
  );
}

/// Splash: ilk açılış mı değil mi kontrol eder
class _SplashRedirect extends StatefulWidget {
  const _SplashRedirect();

  @override
  State<_SplashRedirect> createState() => _SplashRedirectState();
}

class _SplashRedirectState extends State<_SplashRedirect> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // SharedPreferences kontrolü main.dart'ta yapılıyor,
    // buradan sadece auth durumuna göre yönlendir
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
