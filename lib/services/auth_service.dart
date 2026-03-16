// lib/services/auth_service.dart (GÜNCELLENDİ - Supabase SMS OTP)

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/models.dart' as app_models;

class AuthService extends ChangeNotifier {
  final _supabase = SupabaseService();

  User? _currentUser;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _pendingPhone; // OTP bekleyen telefon

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => supabase.auth.currentUser != null;
  String? get pendingPhone => _pendingPhone;

  AuthService() {
    // Auth durum değişikliklerini dinle
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _currentUser = null;
        notifyListeners();
      }
    });

    // Mevcut oturumu yükle
    if (supabase.auth.currentUser != null) {
      _loadProfile();
    }
  }

  // TC Kimlik algoritma doğrulaması
  static bool validateTCKimlik(String tc) {
    if (tc.length != 11 || tc[0] == '0') return false;
    if (!RegExp(r'^\d{11}$').hasMatch(tc)) return false;

    int sumOdd = 0, sumEven = 0;
    for (int i = 0; i < 9; i += 2) sumOdd += int.parse(tc[i]);
    for (int i = 1; i < 8; i += 2) sumEven += int.parse(tc[i]);

    int d10 = ((sumOdd * 7) - sumEven) % 10;
    int d11 = (sumOdd + sumEven + int.parse(tc[9])) % 10;

    return d10 == int.parse(tc[9]) && d11 == int.parse(tc[10]);
  }

  // ADIM 1: Telefon + TC doğrula, SMS gönder
  Future<Map<String, dynamic>> sendOTP({
    required String phone,
    required String tcKimlik,
  }) async {
    if (!validateTCKimlik(tcKimlik)) {
      return {'success': false, 'error': 'Geçersiz TC Kimlik Numarası'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.sendOTP(phone);
      _pendingPhone = phone;
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': _parseAuthError(e.message)};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'SMS gönderilemedi. Lütfen tekrar deneyin.'};
    }
  }

  // ADIM 2: OTP doğrula ve giriş tamamla
  Future<Map<String, dynamic>> verifyOTP({
    required String otp,
    required String tcKimlik,
    required String province,
    required String district,
    required String neighborhood,
  }) async {
    if (_pendingPhone == null) {
      return {'success': false, 'error': 'Telefon numarası bulunamadı'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.verifyOTP(
        phone: _pendingPhone!,
        otp: otp,
        tcKimlik: tcKimlik,
        province: province,
        district: district,
        neighborhood: neighborhood,
      );

      await _loadProfile();
      _pendingPhone = null;
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': _parseAuthError(e.message)};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Doğrulama başarısız. Kod hatalı veya süresi dolmuş.'};
    }
  }

  // Profil yükle
  Future<void> _loadProfile() async {
    try {
      _profile = await _supabase.getCurrentUserProfile();
    } catch (e) {
      debugPrint('[AuthService] Profil yüklenemedi: $e');
    }
    notifyListeners();
  }

  // Adres güncelle
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
      rethrow; // UI'ın hatayı göstermesi için
    }
  }

  // Çıkış
  Future<void> logout() async {
    await _supabase.signOut();
  }

  String _parseAuthError(String message) {
    if (message.contains('otp')) return 'Doğrulama kodu hatalı veya süresi dolmuş';
    if (message.contains('phone')) return 'Geçersiz telefon numarası';
    if (message.contains('rate')) return 'Çok fazla deneme. Lütfen bekleyin.';
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
