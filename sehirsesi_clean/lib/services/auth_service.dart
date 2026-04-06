import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  final _supabase = SupabaseService();

  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => supabase.auth.currentUser != null;
  User? get currentUser => supabase.auth.currentUser;

  AuthService() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        notifyListeners();
      }
    });

    if (supabase.auth.currentUser != null) {
      _loadProfile();
    }
  }

  // ─── KAYIT OL ────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'username': username},
      );

      if (response.user != null && response.session != null) {
        await supabase.from('users').upsert({
          'auth_id': response.user!.id,
          'username': username,
          'email': email.trim().toLowerCase(),
          'province': '',
          'district': '',
          'neighborhood': '',
        });
        await _loadProfile();
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': 'Supabase panelinden email doğrulamasını kapatın.',
      };
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': _parseError(e.message)};
    } catch (e) {
      debugPrint('[AuthService] register error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Kayıt başarısız: $e'};
    }
  }

  // ─── GİRİŞ YAP ───────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await _loadProfile();
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } on AuthException catch (e) {
      debugPrint('[AuthService] login AuthException: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': _parseError(e.message)};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Giriş başarısız: $e'};
    }
  }

  // ─── ŞİFRE SIFIRLAMA ─────────────────────────────────────────
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'error': _parseError(e.message)};
    } catch (e) {
      return {'success': false, 'error': 'Şifre sıfırlama maili gönderilemedi.'};
    }
  }

  // ─── KULLANICI ADI DEĞİŞTİR ──────────────────────────────────
  Future<Map<String, dynamic>> updateUsername(String newUsername) async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'success': false, 'error': 'Oturum bulunamadı'};

    try {
      final existing = await supabase
          .from('users')
          .select('id')
          .eq('username', newUsername)
          .neq('auth_id', user.id)
          .maybeSingle();

      if (existing != null) {
        return {'success': false, 'error': 'Bu kullanıcı adı zaten alınmış'};
      }

      await supabase
          .from('users')
          .update({'username': newUsername})
          .eq('auth_id', user.id);

      await supabase.auth.updateUser(
        UserAttributes(data: {'username': newUsername}),
      );

      await _loadProfile();
      return {'success': true};
    } catch (e) {
      debugPrint('[AuthService] updateUsername error: $e');
      return {'success': false, 'error': 'Kullanıcı adı güncellenemedi.'};
    }
  }

  // ─── ÇIKIŞ ───────────────────────────────────────────────────
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // ─── ADRES GÜNCELLE ──────────────────────────────────────────
  Future<void> updateAddress({
    required String province,
    required String district,
    required String neighborhood,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('users').update({
        'province': province,
        'district': district,
        'neighborhood': neighborhood,
      }).eq('auth_id', user.id);
      await _loadProfile();
    } catch (e) {
      debugPrint('[AuthService] Adres güncellenemedi: $e');
      rethrow;
    }
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await _supabase.getCurrentUserProfile();
    } catch (e) {
      debugPrint('[AuthService] Profil yüklenemedi: $e');
    }
    notifyListeners();
  }

  String _parseError(String message) {
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'Bu email zaten kayıtlı';
    }
    if (message.contains('Invalid login') || message.contains('invalid')) {
      return 'Email veya şifre hatalı';
    }
    if (message.contains('Password')) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (message.contains('valid email')) {
      return 'Geçerli bir email adresi girin';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
