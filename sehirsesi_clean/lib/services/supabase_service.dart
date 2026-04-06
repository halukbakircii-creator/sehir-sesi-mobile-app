// lib/services/supabase_service.dart
// Supabase entegrasyonu - tüm backend işlemleri



import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

// Supabase istemcisi
final supabase = Supabase.instance.client;

class SupabaseService {
  // ─── AUTH ─────────────────────────────────────────────────────

  /// Mevcut kullanıcı profili
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('auth_id', user.id)
          .single();
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await supabase.auth.signOut();
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
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Yorum göndermek için önce giriş yapın');
    if (province.trim().isEmpty || district.trim().isEmpty || neighborhood.trim().isEmpty) {
      throw Exception('İl, ilçe ve mahalle seçimi eksik');
    }

    var profile = await getCurrentUserProfile();
    if (profile == null) {
      await supabase.from('users').upsert({
        'auth_id': user.id,
        'username': (user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'kullanici').toString(),
        'email': user.email,
        'province': province,
        'district': district,
        'neighborhood': neighborhood,
      });
      profile = await getCurrentUserProfile();
    }
    if (profile == null || profile['id'] == null) {
      throw Exception('Kullanıcı profili hazırlanamadı');
    }

    final result = await supabase.from('feedbacks').insert({
      'user_id': profile['id'],
      'province': province,
      'district': district,
      'neighborhood': neighborhood,
      'category': category.name,
      'rating': rating,
      'comment': comment.trim(),
      'is_anonymous': isAnonymous,
    }).select('id').single();

    final feedbackId = result['id'].toString();
    try {
      await supabase.functions.invoke('analyze-feedback', body: {'feedback_id': feedbackId});
    } catch (_) {}
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
    try {
      final rpcData = await supabase
          .rpc('get_all_neighborhoods_with_scores')
          .eq('province', province)
          .eq('district', district);
      final rpcList = List<Map<String, dynamic>>.from(rpcData as List);
      if (rpcList.isNotEmpty) {
        final mapped = rpcList.map(_mapToNeighborhoodStats).toList();
        mapped.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        return mapped;
      }
    } catch (_) {}

    final neighborhoods = await getNeighborhoods(province: province, district: district);
    final data = await supabase
        .from('neighborhood_scores')
        .select()
        .eq('province', province)
        .eq('district', district);

    final scoreMap = {
      for (final row in List<Map<String, dynamic>>.from(data as List))
        (row['neighborhood'] as String): row,
    };

    final result = neighborhoods.map((name) {
      final row = scoreMap[name];
      if (row == null) {
        return NeighborhoodStats(
          neighborhood: name,
          district: district,
          province: province,
          overallScore: 50,
          totalFeedbacks: 0,
          categoryScores: const {
            FeedbackCategory.cleaning: 50,
            FeedbackCategory.road: 50,
            FeedbackCategory.security: 50,
            FeedbackCategory.park: 50,
            FeedbackCategory.transport: 50,
            FeedbackCategory.social: 50,
          },
          topIssues: const [],
          topPraises: const [],
          aiReport: null,
        );
      }
      return _mapToNeighborhoodStats(row);
    }).toList();

    result.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return result;
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

  // ─── MAHALLE LİSTESİ ─────────────────────────────────────────
  Future<List<String>> getNeighborhoods({
    required String province,
    required String district,
  }) async {
    try {
      final data = await supabase
          .from('neighborhoods')
          .select('name')
          .eq('province', province)
          .eq('district', district)
          .order('name');
      return (data as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      return [];
    }
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
      neighborhood: (data['neighborhood'] ?? '').toString(),
      district: (data['district'] ?? '').toString(),
      province: (data['province'] ?? '').toString(),
      overallScore: (data['overall_score'] as num?)?.toDouble() ?? 50,
      totalFeedbacks: (data['total_feedbacks'] as num?)?.toInt() ?? 0,
      categoryScores: {
        FeedbackCategory.cleaning: (data['score_cleaning'] as num?)?.toDouble() ?? 50,
        FeedbackCategory.road: (data['score_road'] as num?)?.toDouble() ?? 50,
        FeedbackCategory.security: (data['score_security'] as num?)?.toDouble() ?? 50,
        FeedbackCategory.park: (data['score_park'] as num?)?.toDouble() ?? 50,
        FeedbackCategory.transport: (data['score_transport'] as num?)?.toDouble() ?? 50,
        FeedbackCategory.social: (data['score_social'] as num?)?.toDouble() ?? 50,
      },
      topIssues: const [],
      topPraises: const [],
      aiReport: data['ai_report'] as String?,
    );
  }
}

