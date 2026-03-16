// lib/services/supabase_service.dart
// Supabase entegrasyonu - tüm backend işlemleri

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

// Supabase istemcisi
final supabase = Supabase.instance.client;

class SupabaseService {
  // ─── AUTH: SMS OTP ────────────────────────────────────────────

  /// SMS OTP gönder
  Future<void> sendOTP(String phone) async {
    // Türkiye formatı: +90XXXXXXXXXX
    final formatted = phone.startsWith('+') ? phone : '+90${phone.replaceAll(RegExp(r'^0'), '')}';
    try {
      await supabase.auth.signInWithOtp(phone: formatted);
    } on AuthException catch (e) {
      throw Exception('SMS gönderilemedi: \${e.message}');
    }
  }

  /// OTP doğrula ve giriş yap
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String otp,
    required String tcKimlik,
    required String province,
    required String district,
    required String neighborhood,
  }) async {
    final formatted = phone.startsWith('+') ? phone : '+90${phone.replaceAll(RegExp(r'^0'), '')}';

    // TC hash oluştur (SHA-256)
    final tcHash = sha256.convert(utf8.encode(tcKimlik)).toString();

    final response = await supabase.auth.verifyOTP(
      phone: formatted,
      token: otp,
      type: OtpType.sms,
    );

    // Kullanıcı metadata güncelle
    if (response.user != null) {
      await supabase.auth.updateUser(UserAttributes(
        data: {
          'tc_hash': tcHash,
          'province': province,
          'district': district,
          'neighborhood': neighborhood,
        },
      ));

      // Profili güncelle
      await supabase.from('users').upsert({
        'auth_id': response.user!.id,
        'phone': formatted,
        'tc_hash': tcHash,
        'province': province,
        'district': district,
        'neighborhood': neighborhood,
        'is_verified': true,
      });
    }

    return response;
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Mevcut kullanıcı profili
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .single();

    return data;
  }

  // ─── GERİ BİLDİRİMLER ────────────────────────────────────────

  /// Geri bildirim ekle (AI analizi otomatik tetiklenir)
  Future<String> submitFeedback({
    required String province,
    required String district,
    required String neighborhood,
    required FeedbackCategory category,
    required int rating,
    required String comment,
    bool isAnonymous = false,
  }) async {
    final userProfile = await getCurrentUserProfile();
    if (userProfile == null) throw Exception('Kullanıcı bulunamadı');

    final result = await supabase.from('feedbacks').insert({
      'user_id': userProfile['id'],
      'province': province,
      'district': district,
      'neighborhood': neighborhood,
      'category': category.name,
      'rating': rating,
      'comment': comment,
      'is_anonymous': isAnonymous,
    }).select('id').single();

    final feedbackId = result['id'] as String;

    // Edge Function ile AI analizi tetikle (arka planda)
    supabase.functions.invoke('analyze-feedback', body: {'feedback_id': feedbackId});

    return feedbackId;
  }

  /// Mahalle geri bildirimleri
  Future<List<Map<String, dynamic>>> getNeighborhoodFeedbacks({
    required String province,
    required String district,
    required String neighborhood,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await supabase
        .from('feedbacks')
        .select('id, category, rating, comment, ai_sentiment, ai_urgency, created_at')
        .eq('province', province)
        .eq('district', district)
        .eq('neighborhood', neighborhood)
        .eq('is_anonymous', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  // ─── MAHALLE SKORLARI ─────────────────────────────────────────

  /// Tek mahalle skoru
  Future<NeighborhoodStats?> getNeighborhoodScore({
    required String province,
    required String district,
    required String neighborhood,
  }) async {
    try {
      final data = await supabase
          .from('neighborhood_scores')
          .select()
          .eq('province', province)
          .eq('district', district)
          .eq('neighborhood', neighborhood)
          .single();

      return _mapToNeighborhoodStats(data);
    } catch (_) {
      return null;
    }
  }

  /// İlçedeki tüm mahalle skorları
  Future<List<NeighborhoodStats>> getDistrictNeighborhoodScores({
    required String province,
    required String district,
  }) async {
    final data = await supabase
        .from('neighborhood_scores')
        .select()
        .eq('province', province)
        .eq('district', district)
        .order('overall_score', ascending: false);

    return (data as List).map((d) => _mapToNeighborhoodStats(d)).toList();
  }

  /// İl geneli ilçe özeti
  Future<List<Map<String, dynamic>>> getProvinceDistrictSummary(String province) async {
    // Her ilçenin ortalama skorunu hesapla
    final data = await supabase
        .from('neighborhood_scores')
        .select('district, overall_score, total_feedbacks')
        .eq('province', province);

    // İlçe bazlı gruplama (Dart tarafında)
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final row in (data as List)) {
      final d = row['district'] as String;
      if (!grouped.containsKey(d)) {
        grouped[d] = {'district': d, 'total': 0.0, 'count': 0, 'feedbacks': 0};
      }
      grouped[d]!['total'] += row['overall_score'];
      grouped[d]!['count'] += 1;
      grouped[d]!['feedbacks'] += row['total_feedbacks'];
    }

    return grouped.values.map((v) => {
      'district': v['district'],
      'score': (v['total'] / v['count']).toDouble(),
      'feedbacks': v['feedbacks'],
      'neighborhood_count': v['count'],
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  }

  // ─── GERÇEK ZAMANLI AKIŞ ─────────────────────────────────────

  /// Mahalle skorunu gerçek zamanlı dinle
  RealtimeChannel subscribeToNeighborhoodScore({
    required String province,
    required String district,
    required String neighborhood,
    required void Function(NeighborhoodStats) onUpdate,
  }) {
    return supabase
        .channel('score:$province:$district:$neighborhood')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'neighborhood_scores',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'neighborhood',
            value: neighborhood,
          ),
          callback: (payload) {
            final stats = _mapToNeighborhoodStats(payload.newRecord);
            onUpdate(stats);
          },
        )
        .subscribe();
  }

  /// Yeni geri bildirimleri gerçek zamanlı dinle (belediye paneli)
  RealtimeChannel subscribeToNewFeedbacks({
    required String province,
    required void Function(Map<String, dynamic>) onNew,
  }) {
    return supabase
        .channel('feedbacks:$province')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'feedbacks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'province',
            value: province,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }

  // ─── AI RAPORLAR ──────────────────────────────────────────────

  /// Mahalle AI raporu oluştur (Edge Function)
  Future<String> generateNeighborhoodReport({
    required String province,
    required String district,
    required String neighborhood,
  }) async {
    final response = await supabase.functions.invoke(
      'generate-report',
      body: {
        'type': 'neighborhood',
        'province': province,
        'district': district,
        'neighborhood': neighborhood,
      },
    );

    if (response.data['success'] == true) {
      return response.data['report'] as String;
    }
    throw Exception('Rapor oluşturulamadı');
  }

  /// Belediye yönetici raporu oluştur
  Future<String> generateMunicipalityReport(String province) async {
    final response = await supabase.functions.invoke(
      'generate-report',
      body: {'type': 'municipality', 'province': province},
    );

    if (response.data['success'] == true) {
      return response.data['report'] as String;
    }
    throw Exception('Rapor oluşturulamadı');
  }

  // ─── YARDIMCI ─────────────────────────────────────────────────

  // ─── REALTIME TEMİZLEME ─────────────────────────────────────────
  /// Realtime kanalları temizle. dispose() içinde çağırın:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _channel?.unsubscribe();
  ///   supabase.removeAllChannels();
  ///   super.dispose();
  /// }
  /// ```
  static Future<void> removeAllChannels() async {
    await supabase.removeAllChannels();
  }

  NeighborhoodStats _mapToNeighborhoodStats(Map<String, dynamic> data) {
    return NeighborhoodStats(
      neighborhood: data['neighborhood'],
      district: data['district'],
      province: data['province'],
      overallScore: (data['overall_score'] as num).toDouble(),
      totalFeedbacks: data['total_feedbacks'] as int,
      categoryScores: {
        FeedbackCategory.cleaning:  (data['score_cleaning']  as num).toDouble(),
        FeedbackCategory.road:       (data['score_road']      as num).toDouble(),
        FeedbackCategory.security:   (data['score_security']  as num).toDouble(),
        FeedbackCategory.park:       (data['score_park']      as num).toDouble(),
        FeedbackCategory.transport:  (data['score_transport'] as num).toDouble(),
        FeedbackCategory.social:     (data['score_social']    as num).toDouble(),
      },
      topIssues: const [],
      topPraises: const [],
      aiReport: data['ai_report'] as String?,
    );
  }
}
