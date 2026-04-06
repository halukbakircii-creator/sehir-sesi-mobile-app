// lib/screens/splash_screen.dart
// Logo ile açılış ekranı

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'city_selection_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasCity = (prefs.getString('selected_city') ?? '').isNotEmpty;
    if (!hasCity) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CitySelectionScreen(isFirstTime: true)),
      );
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => session != null ? const HomeScreen() : const LoginScreen()),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Logo
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.4), blurRadius: 40, spreadRadius: 5)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 28),
              // Uygulama adı
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Şehir', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                TextSpan(text: 'Sesi', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF64B5F6), letterSpacing: -1)),
              ])),
              const SizedBox(height: 10),
              const Text('Türkiye\'nin Nabzı', style: TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.w400)),
              const SizedBox(height: 48),
              // Loading indicator
              SizedBox(width: 140, child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
                borderRadius: BorderRadius.circular(4),
                minHeight: 3,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
