import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'services/filter_service.dart';
import 'services/places_service.dart';
import 'services/route_service.dart';
import 'screens/guest_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/city_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FilterService()),
        Provider(create: (_) => PlacesService()),
        Provider(create: (_) => RouteService()),
      ],
      child: const SehirSesApp(),
    ),
  );
}

class SehirSesApp extends StatelessWidget {
  const SehirSesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ŞehirSes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const _AppNavigator(),
    );
  }
}

class _AppNavigator extends StatefulWidget {
  const _AppNavigator({super.key});

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  bool _checkingFirstTime = true;
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCity = prefs.getString('selected_city') != null;
    setState(() {
      _isFirstTime = !hasCity;
      _checkingFirstTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingFirstTime) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isFirstTime) {
      return const CitySelectionScreen(isFirstTime: true);
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const GuestHomeScreen();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const GuestHomeScreen();
      },
    );
  }
}